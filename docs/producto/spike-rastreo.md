# Spike 1 — Rastreo del conductor en segundo plano

> **HU-011 · RF-62 · RNF-10 · E03-HU15.** Prueba de tiempo fijo: no lleva
> puntos. Construida el 25-oct-2026. **Todavía no hay mediciones**: ese día no
> había ningún teléfono ni emulador conectado (ver [Estado](#10-estado)).

## 1. La pregunta

¿La app del conductor **sigue enviando su ubicación GPS a Supabase** cuando
la app está **minimizada** y cuando la **pantalla está apagada**?

Se responde con un número por fase, no con una impresión: cuántas de las
ubicaciones que debían llegar llegaron, y cuál fue el silencio más largo.

## 2. Por qué es el riesgo principal

HU-011 promete que el estudiante ve en el mapa dónde viene la unidad. Eso solo
funciona si el teléfono del conductor transmite **todo el viaje**, y durante
un viaje el conductor no tiene Cupo abierta: usa Waze o WhatsApp, o deja el
teléfono bloqueado en el soporte.

Android hace todo lo posible por frenar a las apps que no están a la vista:

- **Límites de segundo plano** (Android 8+): una app sin servicio en primer
  plano deja de recibir ubicaciones a los pocos minutos de minimizarse.
- **Doze y App Standby**: con la pantalla apagada y el teléfono quieto,
  Android agrupa el trabajo en ventanas y corta la red entre una y otra.
- **Fabricantes**: Xiaomi, Huawei, Samsung y otros agregan su propio ahorro de
  batería, que cierra servicios que Android puro dejaría vivir
  ([dontkillmyapp.com](https://dontkillmyapp.com) lleva el registro por marca).
- **Permisos**: «Mientras se usa la app» y «Permitir todo el tiempo» no dan lo
  mismo, y Google Play pide justificar el segundo.

Si nada de esto se mide, HU-011 puede verse perfecta en la demostración (app
abierta en la mano) y fallar en la primera ruta real. Si falla, cambia el
diseño: habría que pedirle al conductor que deje Cupo abierta, o cambiar de
técnica. Por eso se prueba antes de construir el viaje en vivo.

## 3. Qué se construyó

| Pieza | Dónde | Para qué |
| --- | --- | --- |
| Tabla `spike_posiciones`, vista `spike_sesiones`, función `spike_reporte()` | [`supabase/migrations/20261026000001_spike_rastreo.sql`](../../supabase/migrations/20261026000001_spike_rastreo.sql) | Guardar cada muestra y calcular el resultado. Aplicada en el proyecto de desarrollo. |
| Pantalla «Prueba de rastreo» | `cupo/lib/features/spike_rastreo/` | Correr el protocolo y ver el resultado en el teléfono. |
| Botón «Prueba de rastreo» | Inicio del conductor, sobre el mapa | Entrada a la pantalla. **Solo existe en compilaciones de depuración** (`kDebugMode`). |
| Canal `cupo/spike_rastreo` | `cupo/android/app/src/main/kotlin/com/cupo/cupo/MainActivity.kt` | Permiso de notificaciones, pantalla encendida en la fase 1, estado de la pantalla y de la batería, avisos de cambio de fase. Sin dependencias nuevas. |
| Permiso `WAKE_LOCK` | `AndroidManifest.xml` | Lo exige el *wake lock* del servicio de ubicación. Se concede al instalar. |
| Script de adb | [`scripts/spike_rastreo_adb.sh`](../../scripts/spike_rastreo_adb.sh) | Cambiar de fase sin tocar el teléfono (opcional). |
| Pruebas | `cupo/test/features/spike_rastreo/` | Cálculo de fases, cola de reintentos, filas, reporte y pantalla. |

Cómo transmite la app durante la prueba:

1. `Geolocator.getPositionStream` con `AndroidSettings`: precisión alta,
   `distanceFilter: 0` e `intervalDuration` de 5 s, para que un teléfono quieto
   también produzca una muestra cada 5 s.
2. `foregroundNotificationConfig`: el flujo corre como **servicio en primer
   plano de tipo `location`**, con una notificación fija. Es lo que Android
   exige para seguir entregando ubicaciones con la app fuera de la vista.
3. *Wake lock* y *wifi lock* del servicio (activables en la pantalla): sin
   ellos, con la pantalla apagada el procesador puede dormirse entre
   ubicaciones.
4. Cada muestra se inserta en `spike_posiciones` por HTTP (PostgREST). Si el
   envío falla, la muestra se queda en una cola en memoria **con su número y su
   hora de captura** y se reintenta cada 5 s. El reintento usa
   `ON CONFLICT (sesion_id, seq) DO NOTHING`: si un envío llegó pero se perdió
   la respuesta, no se duplica.

## 4. Diseño de la medición

### 4.1 Fases guiadas por tiempo

La prueba son tres fases seguidas de igual duración. La fase la decide **el
reloj**, no lo que la persona toque, así nadie tiene que interactuar con la
app minimizada para avanzar (que es justo lo que se quiere medir).

| Fase | Minutos (estándar) | Qué hace la persona | Qué se mide |
| --- | --- | --- | --- |
| `1_primer_plano` | 0–10 | Nada: Cupo abierta, la pantalla se queda encendida sola | La línea base: así debería verse una fase sana |
| `2_minimizada` | 10–20 | Toca Inicio y usa el teléfono normal, con la pantalla encendida | Si el servicio sobrevive fuera de la vista |
| `3_pantalla_apagada` | 20–30 | Bloquea el teléfono y no lo toca | Si sobrevive a Doze y al ahorro del fabricante |

- El reloj **arranca con la primera ubicación**, no al tocar «Empezar»: el
  tiempo que tarda el GPS en engancharse no cuenta contra la fase 1.
- Duraciones: **corta** (2 min por fase, ensayo; no vale como evidencia),
  **estándar** (10 min, la que cuenta) y **larga** (20 min, da tiempo a que
  Android entre en reposo profundo).
- En cada cambio de fase el teléfono vibra y llega una notificación con lo que
  hay que hacer y hasta qué hora. La pantalla muestra el horario completo.
- Las fases se cuentan con la hora del teléfono y no con un cronómetro
  monótono: en Android ese reloj se detiene mientras el procesador duerme, y
  desfasaría justo la fase 3.

### 4.2 Qué se guarda por muestra

| Columna | Qué es |
| --- | --- |
| `sesion_id`, `seq` | La corrida y el número de muestra dentro de ella. `seq` se asigna **al capturar** y no cambia en los reintentos. |
| `capturada_en` | Hora del teléfono en que la ubicación llegó a la app. |
| `enviada_en` | Hora del teléfono en que salió el envío que la entregó. |
| `recibida_en` | Hora del **servidor** al insertarla. |
| `fijada_en` | Hora del fix según el sistema de ubicación. |
| `lat`, `lng`, `precision_m` | La posición y su incertidumbre. |
| `fase` | Fase según el reloj. |
| `estado_app` | `AppLifecycleState` de Flutter: `resumed`, `paused`, … |
| `pantalla_encendida` | Si la pantalla estaba encendida (`PowerManager.isInteractive`). |
| `intentos` | En qué intento llegó. |
| `wakelock`, `permiso`, `bateria_sin_restriccion`, `dispositivo` | La configuración de la corrida, repetida en cada fila. |

`estado_app` y `pantalla_encendida` sirven de **control**: confirman que en la
fase 2 la app estaba de verdad minimizada (`paused` con pantalla encendida) y
en la fase 3 de verdad con la pantalla apagada. Si no coinciden, la persona no
siguió el protocolo y la corrida no vale.

### 4.3 Las métricas

`spike_reporte(sesion)` devuelve una fila por fase:

| Métrica | Cálculo | Cómo se lee |
| --- | --- | --- |
| `esperadas` | duración de la fase / 5 s | 120 en una fase de 10 min |
| `recibidas` | filas cuya `capturada_en` cae en la fase | |
| **`cobertura_pct`** | recibidas / esperadas, tope 100 | Qué parte de la fase quedó cubierta |
| **`brecha_max_s`** | mayor silencio entre capturas consecutivas, contando el inicio y el fin de la fase como bordes | Lo que el estudiante vería como «la unidad se quedó quieta». Un silencio al final de la fase también cuenta. |
| `brecha_p95_s` | percentil 95 de esos silencios | Si es ≈5 s, el ritmo normal se mantuvo y la brecha máxima es un evento aislado |
| `perdidas` | huecos en `seq` | Capturadas que **nunca llegaron** |
| `tardias` | `enviada_en − capturada_en` > 30 s | Capturadas que **llegaron tarde** (esperaron en la cola). Mismo reloj: no le afecta el desfase. |
| `latencia_mediana_s` | mediana de `recibida_en − capturada_en` | Retraso típico de punta a punta. ⚠️ Resta la hora del servidor menos la del teléfono: si el reloj del teléfono está adelantado o atrasado, el número se corre en la misma cantidad (puede salir negativo). Para comparar corridas, úsalo solo dentro del mismo teléfono. |
| `estados` | conteo por estado de la app y pantalla | `paused (pantalla apagada) 118 · paused 2` |
| `cumple` | criterio de la sección 5 | |
| `completa` | si la fase ya terminó | Una fase incompleta no cuenta |

### 4.4 Los tres tipos de falla

| Síntoma en el reporte | Qué pasó | Causa típica |
| --- | --- | --- |
| Brecha grande **sin** huecos de `seq` | El teléfono **no capturó**: la app no recibió ubicaciones | Android congeló o mató el servicio; ahorro de batería |
| Huecos de `seq` (`perdidas` > 0) | Capturó, pero **nunca llegaron** | El proceso murió con muestras en la cola en memoria |
| `tardias` > 0 sin brechas | Capturó a tiempo y **llegaron tarde** | Sin red un rato (Doze corta la red), y la cola se puso al día después |

## 5. Criterio de éxito

> **Pasa** si, en una corrida **estándar** (10 min por fase) en un teléfono
> físico **desconectado del cargador**, las **tres** fases cumplen:
>
> - cobertura **≥ 90 %**, y
> - brecha máxima **≤ 30 s**.

Por qué esos números: con una muestra cada 5 s, el 90 % deja margen para el
arranque del GPS y alguna lectura perdida, pero no para cortes sostenidos. Y
30 s es el límite de lo creíble en el mapa: a 30 km/h la unidad avanza 250 m
en ese tiempo, más o menos una cuadra larga; más allá, el estudiante ve una
unidad detenida que en realidad se mueve.

Resultado por teléfono:

- **Pasa** — cumple con el permiso «Mientras se usa la app» y la batería en
  su configuración de fábrica.
- **Pasa con ajustes** — solo cumple después de quitar la optimización de
  batería o con «Permitir todo el tiempo». Es viable, pero el ajuste se vuelve
  un paso obligatorio del alta del conductor (y del manual).
- **No pasa** — no cumple ni con los ajustes. HU-011 necesita otra técnica o
  pedirle al conductor que deje Cupo abierta.

Para la tesis conviene probar **al menos dos marcas**, una de ellas Xiaomi,
Huawei o Samsung (EA-18).

## 6. Protocolo paso a paso

### 6.1 Preparar (una sola vez)

1. **Instala la app de prueba.** Copia el APK al teléfono
   (`cupo/build/app/outputs/flutter-apk/app-debug.apk`) y ábrelo; Android
   pedirá permitir «instalar apps desconocidas». O, con el teléfono conectado
   por USB y la depuración USB activa:
   ```bash
   adb install -r cupo/build/app/outputs/flutter-apk/app-debug.apk
   ```
   Si ya tenías Cupo de otra compilación y no deja instalar, desinstálala
   primero.
2. **Entra como conductor** con `mail@gmail.com` / `123`. Caes en «Hoy».
3. En el inicio, arriba a la izquierda sobre el mapa, toca **«Prueba de
   rastreo»**.
4. Antes de empezar, en el teléfono:
   - **Desconecta el cargador.** Cargando, Android no aplica ahorro de
     batería y la prueba no dice nada.
   - **Sube el tiempo de espera de la pantalla al máximo** (Ajustes › Pantalla
     › Tiempo de espera). Si no, en la fase 2 la pantalla se apaga sola y la
     fase 2 se convierte en otra fase 3.
   - Deja los datos móviles (o el wifi) encendidos.
   - **No toques la batería de Cupo todavía**: la primera corrida es con la
     configuración de fábrica.

### 6.2 Ensayo de 6 minutos (opcional)

Elige **2 minutos por fase** y sigue los pasos de 6.3. Sirve para ver que los
permisos, las notificaciones y el envío funcionan. **No cuenta como
evidencia.**

### 6.3 La prueba (30 minutos)

1. En «Prueba de rastreo», elige **10 minutos por fase** y deja marcado
   «Mantener el procesador despierto».
2. Toca **«Empezar prueba»**. Acepta los permisos:
   - Ubicación: **«Mientras se usa la app»** (es el que pediría la app real).
   - Notificaciones: **Permitir** (sin esto no verás los avisos de cada fase).
3. Aparece «Buscando señal GPS…». Si tarda más de un minuto, acércate a una
   ventana. Cuando llega la primera ubicación, la pantalla cambia a
   **«FASE 1 DE 3 · Deja Cupo abierta»** y muestra el horario de las tres
   fases. **Anota la hora** o toma captura del horario.
4. **Fase 1 (10 min):** no toques nada. La pantalla se queda encendida sola.
   Arriba aparece la notificación fija «Cupo · Prueba de rastreo».
5. **Fase 2 (10 min):** el teléfono vibra y llega el aviso «Fase 2 de 3:
   minimiza Cupo». Toca **Inicio** (no cierres Cupo desde Recientes) y usa el
   teléfono normal: WhatsApp, YouTube… con la pantalla encendida.
6. **Fase 3 (10 min):** llega el aviso «Fase 3 de 3: apaga la pantalla».
   Bloquea el teléfono con el botón de encendido y **déjalo quieto** hasta que
   llegue el aviso de fin.
7. Al final llega «Prueba de rastreo terminada». Desbloquea y abre Cupo: la
   pantalla muestra el **resultado** por fase («Cumple en las tres fases» o «No
   cumple») y el identificador de la sesión (botón «Copiar»).
8. Anota el resultado en la [tabla de la sección 9](#9-tabla-de-resultados)
   y guarda una captura de pantalla del resultado.

Si quieres detenerla antes, toca «Detener prueba»: lo que falte contará como
hueco y el resultado sale como parcial.

### 6.4 Las corridas que hacen falta

| Corrida | Permiso | Batería de Cupo | Wake lock | Para qué |
| --- | --- | --- | --- | --- |
| A | Mientras se usa la app | De fábrica | Sí | La respuesta principal |
| B (si A no pasa) | Mientras se usa la app | **Sin restricciones** | Sí | ¿Basta con quitar el ahorro de batería? |
| C (si B no pasa) | **Permitir todo el tiempo** | Sin restricciones | Sí | ¿Hace falta el permiso de segundo plano? |
| D (opcional) | El de la mejor corrida | El de la mejor corrida | **No** | ¿El wake lock es necesario? |

La pantalla muestra el estado actual del permiso y de la batería, con enlaces
para cambiarlos («Permitir todo el tiempo», «Quitar la restricción»). La
configuración de cada corrida queda guardada sola en la base.

### 6.5 Automatizar los cambios de fase con adb (opcional)

Con el teléfono conectado por USB, desde la raíz del repositorio en Git Bash:

```bash
bash scripts/spike_rastreo_adb.sh 10          # fases de 10 min
bash scripts/spike_rastreo_adb.sh 10 --doze   # y fuerza el reposo profundo en la fase 3
```

Empieza la prueba en el teléfono y, cuando diga «FASE 1 DE 3», pulsa Enter en
la terminal. El script pulsa Inicio, apaga la pantalla y la vuelve a encender
a su hora, le hace creer a Android que el cargador está desconectado
(`dumpsys battery unplug`) y guarda el logcat del servicio. Aun así, el cable
USB carga el teléfono de verdad: **la corrida que vale como evidencia es la
manual, sin cable** (o por depuración inalámbrica).

## 7. Leer el resultado en Supabase

En el SQL Editor del proyecto de desarrollo
(`wphwhmdgumeinyfznnqj`). Como administrador del panel se ven todas las
sesiones; las consultas del SQL Editor corren como `postgres`, que también las
ve todas.

**Las sesiones**, la más reciente primero:

```sql
select sesion_id, inicio, minutos_por_fase, dispositivo, permiso, wakelock,
       bateria_sin_restriccion, muestras, ultima_seq
  from public.spike_sesiones
 order by inicio desc;
```

**El reporte de una sesión** (el mismo que muestra la app):

```sql
select * from public.spike_reporte('PEGA-AQUÍ-EL-SESION-ID');
```

**El veredicto** (`true` = pasa; `null` = faltan fases completas):

```sql
select case when bool_or(completa and cumple is false) then false
            when count(*) filter (where completa) = 3 then bool_and(cumple)
       end as pasa
  from public.spike_reporte('PEGA-AQUÍ-EL-SESION-ID');
```

**Otro criterio** (por ejemplo, 95 % y 20 s), sin tocar la función:

```sql
select fase, cobertura_pct, brecha_max_s, cumple
  from public.spike_reporte('PEGA-AQUÍ-EL-SESION-ID', 95, 20);
```

**Diagnóstico: los diez silencios más largos**, con lo que pasaba al volver:

```sql
with s as (
  select seq, fase, capturada_en, estado_app, pantalla_encendida, intentos,
         lag(capturada_en) over (order by capturada_en) as anterior,
         lag(seq)          over (order by capturada_en) as seq_anterior
    from public.spike_posiciones
   where sesion_id = 'PEGA-AQUÍ-EL-SESION-ID'
)
select fase, anterior, capturada_en as volvio,
       extract(epoch from capturada_en - anterior)::int as silencio_s,
       seq - seq_anterior - 1 as seq_perdidas,
       estado_app, pantalla_encendida, intentos
  from s
 where anterior is not null
 order by silencio_s desc
 limit 10;
```

Un silencio con `seq_perdidas = 0` es una ubicación que nunca se capturó; con
`seq_perdidas > 0`, muestras que se perdieron en el camino.

## 8. Si no pasa

Primero mira **qué tipo de falla** es (sección 4.4) y **en qué fase**.

| Lo que se ve | Prueba esto, en orden |
| --- | --- |
| Falla también la fase 1 | No es segundo plano: revisa que el GPS esté encendido, el permiso de ubicación precisa y que el teléfono vea el cielo. Repite. |
| Falla la fase 2 o la 3 con brechas grandes y sin `perdidas` | 1. Quita la optimización de batería de Cupo: Ajustes › Apps › Cupo › Batería › **Sin restricciones** (o el enlace «Quitar la restricción» de la pantalla). 2. Ajustes del fabricante: **Xiaomi** (MIUI/HyperOS): Batería › Ahorro de batería de la app › Sin restricciones, y activar **Inicio automático**; **Samsung**: Batería › Límites de uso en segundo plano › sacar Cupo de «Apps en suspensión» y agregarla a «Apps que nunca se suspenden»; **Huawei**: Batería › Inicio de apps › Cupo en **manual** con las tres opciones activas. Guía por marca en [dontkillmyapp.com](https://dontkillmyapp.com). 3. Permiso **«Permitir todo el tiempo»** (enlace en la pantalla). 4. Confirma que la corrida tuvo *wake lock*. |
| `perdidas` > 0 | El proceso murió con muestras en la cola. Las mismas medidas de arriba. Para producción: guardar la cola en disco (sqflite ya está en el proyecto), no solo en memoria. |
| `tardias` altas, sin brechas | La captura sigue, pero la red se corta (Doze). Prueba con datos móviles en vez de wifi y con *wake lock*. Si solo hay retraso y nada se pierde, puede ser aceptable: el estudiante ve la unidad con atraso, no detenida. |
| No aparece la notificación fija | Falta el permiso de notificaciones (Android 13+). El servicio corre igual, pero dalo: Ajustes › Apps › Cupo › Notificaciones. |
| `estados` no coincide con la fase | La corrida no siguió el protocolo (pantalla apagada en la fase 2, Cupo abierta en la 3…). Repítela. |

Cada ajuste que haga falta para pasar es un **hallazgo**: va a la tabla, al
informe de spikes (E03-HU17) y, si se mantiene, a los pasos de alta del
conductor y al manual.

### Si nada funciona

Las alternativas, de menor a mayor costo: pedir el ajuste de batería como
paso obligatorio del alta; mantener Cupo abierta con la pantalla encendida
durante el viaje (como hacen las apps de navegación); o un servicio nativo con
su propio motor de Flutter (paquetes tipo `flutter_background_geolocation`),
que es una decisión de arquitectura y va escrita antes de entrar.

## 9. Tabla de resultados

Una fila por fase y corrida. «Resultado» es *Cumple* / *No cumple* por fase;
la última columna, el veredicto de la corrida (*Pasa*, *Pasa con ajustes*,
*No pasa*).

| Fecha | Teléfono | Android | Corrida | Permiso | Batería | Wake lock | Min/fase | Fase | Cobertura | Brecha máx. | p95 | Perdidas | Tardías | Resultado | Veredicto | Sesión |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | A | | | | 10 | 1 · primer plano | % | s | s | | | | | |
| | | | A | | | | 10 | 2 · minimizada | % | s | s | | | | | |
| | | | A | | | | 10 | 3 · pantalla apagada | % | s | s | | | | | |

Junto a la tabla conviene guardar la captura del resultado en la app y anotar
la capa del fabricante (One UI, MIUI/HyperOS, EMUI…) y su versión.

## 10. Estado

**25-oct-2026.** Construido, probado y aplicado; **no medido**.

- Sin teléfono conectado (`adb devices` vacío) y sin emulador instalado, así
  que no se corrió ninguna sesión. No hay números todavía; la tabla de la
  sección 9 está vacía a propósito.
- Un emulador tampoco serviría como evidencia: no trae el ahorro de batería
  de los fabricantes, que es justo lo que se quiere medir. Sirve, como mucho,
  para ver que el flujo corre de punta a punta.
- Lo que sí está verificado: `spike_reporte()` se probó en una transacción
  revertida con una sesión sintética (dos muestras perdidas, una tardía y un
  silencio de 70 s en la fase 3) y detectó las tres cosas; la inserción como
  el conductor de prueba pasó las políticas RLS y los privilegios por columna.

## 11. Hallazgo del código (no medido): Realtime se desconecta en segundo plano

RF-62 y E03-HU15-T3 plantean enviar la posición **por un canal broadcast de
Realtime** desde el teléfono del conductor. Al revisar `supabase_flutter`
(2.17.2, la versión del proyecto) para este spike apareció un problema que
ninguna prueba en primer plano detectaría: el paquete escucha el ciclo de vida
de la app y, **al pasar a `paused` (minimizada o pantalla apagada),
desconecta el WebSocket de Realtime**; lo reconecta al volver a `resumed`. Es
decir: aunque el GPS siga entregando ubicaciones en segundo plano, un
`channel.sendBroadcastMessage` desde el conductor no saldría.

Por eso este spike envía por **HTTP (PostgREST)**, que no depende del
WebSocket. Para HU-011 la consecuencia probable es: el conductor **escribe**
su posición por HTTP (un `insert` o una RPC) y los estudiantes, que sí tienen
la app abierta, **escuchan** por Realtime (cambios de la tabla, o un broadcast
que emita la base con un trigger). Es una deducción del código, no una
medición: se confirma o se descarta en la decisión del canal (E12-HU02).

Dos detalles más del mismo paquete, para la misma decisión: al pasar a
`paused` también detiene el refresco automático del token de sesión; no
rompe el envío por HTTP, porque cada petición renueva el token si venció, pero
sí lo haría un canal que dependa de la sesión abierta.

## 12. Cómo quitar el spike

Cuando HU-011 tenga su propia tabla de posiciones:

1. En Supabase (SQL Editor del proyecto de desarrollo):
   ```sql
   drop view     if exists public.spike_sesiones;
   drop function if exists public.spike_reporte(uuid, numeric, numeric, numeric);
   drop table    if exists public.spike_posiciones;
   ```
   y una migración nueva con esas mismas líneas, para que el repositorio y la
   base sigan iguales.
2. Borrar `cupo/lib/features/spike_rastreo/` y `cupo/test/features/spike_rastreo/`.
3. Quitar el botón `_BotonPruebaRastreo` de `inicio_conductor_screen.dart` y
   su prueba en `inicio_conductor_screen_test.dart`.
4. Quitar el canal `cupo/spike_rastreo` de `MainActivity.kt`. El permiso
   `WAKE_LOCK` se queda si el rastreo real usa *wake lock*.
5. Borrar `scripts/spike_rastreo_adb.sh`.

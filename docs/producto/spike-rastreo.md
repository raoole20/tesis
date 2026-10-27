# Spike 1 — Rastreo del conductor en segundo plano

> **HU-011 · RF-62 · RNF-10 · E03-HU15.** Prueba de tiempo fijo: no lleva
> puntos. Construida el 25-oct-2026; el modo «Recorrido real» se agregó el
> 26-oct-2026. **Todavía no hay mediciones**: no había ningún teléfono ni
> emulador conectado (ver [Estado](#10-estado)).
>
> Tres modos: **por fases** (secciones 4 a 9, en casa, 30 min), **recorrido
> real** (sección 13, en carro, desde donde estés hasta la URBE) y **simular
> recorrido** (sección 14: la unidad se mueve sola por el mapa, en el
> navegador o con el teléfono quieto; **nunca cuenta como evidencia**).

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
| Tabla `spike_recorridos`, funciones `spike_reporte_ruta()` y `spike_ruta_geojson()`, columnas nuevas de `spike_posiciones` | [`supabase/migrations/20261026000002_spike_recorrido.sql`](../../supabase/migrations/20261026000002_spike_recorrido.sql) | El modo «Recorrido real» (sección 13). Aplicada en el proyecto de desarrollo. |
| Columna `simulada`, tabla `spike_rutas_recalculadas`, permiso `no_aplica`, `spike_reporte_ruta()` rehecha (con `simulada` y `rutas_recalculadas`) | [`supabase/migrations/20261026000003_spike_simulacion.sql`](../../supabase/migrations/20261026000003_spike_simulacion.sql) | La simulación (sección 14) y el recálculo de la ruta (13.3). Aplicada en el proyecto de desarrollo. |
| Pantalla «Prueba de rastreo» | `cupo/lib/features/spike_rastreo/` | Correr el protocolo y ver el resultado en el teléfono. |
| Botón «Prueba de rastreo» | Inicio del conductor, sobre el mapa | Entrada a la pantalla. **Solo existe en compilaciones de depuración** (`kDebugMode`). |
| Canal `cupo/spike_rastreo` | `cupo/android/app/src/main/kotlin/com/cupo/cupo/MainActivity.kt` | Permiso de notificaciones, pantalla encendida en la fase 1, estado de la pantalla y de la batería, avisos de cambio de fase. Sin dependencias nuevas. |
| Permiso `WAKE_LOCK` | `AndroidManifest.xml` | Lo exige el *wake lock* del servicio de ubicación. Se concede al instalar. |
| Script de adb | [`scripts/spike_rastreo_adb.sh`](../../scripts/spike_rastreo_adb.sh) | Cambiar de fase sin tocar el teléfono (opcional). |
| Pruebas | `cupo/test/features/spike_rastreo/` | Cálculo de fases, cola de reintentos, filas, reporte y pantalla; del recorrido: azimut, lectura de OSRM (con respuestas guardadas, sin red), brechas en metros, flechas de sentido, brújula y pantalla. |

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

**25 y 26-oct-2026.** Construido, probado y aplicado (los dos modos);
**no medido**.

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
- `spike_reporte_ruta()` se probó igual (transacción revertida) con dos
  trazas sintéticas sobre la ruta real de OSRM, de 100 muestras cada 5 s y un
  silencio de 65 s:
  - **pegada a la ruta**: desvío mediano 0 m, 100 % de las muestras a ≤ 50 m,
    88,6 % de la ruta cubierta (lo que faltó es el tramo del silencio) y la
    brecha detectada como 65 s y 686 m: no cumple, como debía;
  - **corrida 220 m al norte**: desvío mediano 62 m, p95 218 m, solo 25 % de
    las muestras a ≤ 50 m y 21,7 % de la ruta cubierta.

  Es decir, las métricas separan una traza que sigue las calles de una que
  no. Son datos sintéticos: **no** dicen nada todavía sobre un teléfono real.
- La tercera migración (simulación y recálculo) también se probó revertida:
  una sesión cuya segunda mitad siguió una ruta recalculada (220 m al norte)
  dio desvío 0 m contra la ruta vigente, `rutas_recalculadas = 1` y
  `simulada = true` en el reporte, en la vista y en el GeoJSON.
- La app compila para web (`flutter build web`), así que la simulación se ve
  en localhost. Las sesiones simuladas que se corran **no** son mediciones.

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
   drop table    if exists public.spike_rutas_recalculadas;
   drop function if exists public.spike_ruta_geojson(uuid, numeric);
   drop function if exists public.spike_reporte_ruta(uuid, geography, numeric, numeric, numeric, numeric, numeric, numeric);
   drop table    if exists public.spike_recorridos;
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

## 13. Recorrido real

La prueba por fases mide el segundo plano en condiciones controladas. El
recorrido real mide lo que importa para HU-011: **una ruta de verdad en
carro, desde donde estás hasta la URBE**, con el teléfono usado como lo usa
un chofer (Cupo minimizada con WhatsApp o Waze abiertos, o el teléfono
bloqueado en el soporte). Mientras avanzas, la pantalla muestra tu flecha
sobre el mapa y **cuánto falta** hasta la URBE; si te sales de la ruta, la
recalcula. Al final, dibuja la traza sobre el mapa real y la compara con la
ruta.

### 13.1 Qué cambia respecto de las fases

| | Por fases | Recorrido real |
| --- | --- | --- |
| Dónde | En casa, el teléfono quieto | En carro, por calles de verdad |
| Cuánto dura | 6, 30 o 60 min, por reloj | Lo que dure la ruta; termina al tocar «Terminar recorrido» |
| Qué hace la persona | Lo que dice cada fase | Usa el teléfono como siempre |
| Cómo se separa el resultado | Por fase (reloj) | Por lo que de verdad pasó en cada muestra: Cupo a la vista, minimizada o pantalla apagada |
| Pantalla encendida a la fuerza | Sí, en la fase 1 | No |
| Ruta planificada y mapa | No | Sí: OSRM antes de salir; traza, brechas y flechas al llegar |
| Reporte | `spike_reporte()` | `spike_reporte_ruta()` y `spike_ruta_geojson()` |

En cada muestra se guarda además la **batería** (%, y si estaba enchufada:
también cuenta el cargador del carro), el **rumbo** (del GPS; si el GPS no lo
da —quieto suele mandar 0 o −1—, se calcula con el azimut desde la muestra
anterior y queda marcado en `rumbo_calculado`) y la **velocidad** del GPS.

### 13.2 La ruta: de tu ubicación a la URBE

- **Llegada: fija, la URBE** — 10.709200993030072, −71.62351346346288.
- **Salida: tu ubicación actual.** Al elegir «Recorrido real», la app pide la
  posición (en el navegador, el aviso «usar tu ubicación»; localhost cuenta
  como contexto seguro). Mientras la busca, el mapa se queda en la URBE y dice
  «Buscando tu ubicación…». Con la posición, pide a OSRM la ruta por las
  calles hasta la URBE y encuadra la salida y la llegada.
- **Respaldo:** si no hay permiso, GPS o señal, se usa la Av. 61
  (10.702096062336127, −71.60399954232982) y se avisa. También se puede
  tocar «Salida» y luego el mapa para elegir otra, o «Salir desde mi
  ubicación actual» para volver a intentar. La simulación usa este respaldo
  por omisión, sin pedir la ubicación.

Desde el respaldo, según OSRM (26-oct-2026): **5,39 km y ≈8 min sin
tráfico**, por Avenida 61 → Calle 44 A → Avenida 2 → Calle N → Avenida 5 →
Av. Circunvalación 2 → Av. Paúl René Moreno Camacho → URBE.

**Dónde se cambia:** es una sola constante, `RutaDePrueba.porOmision`, en
`cupo/lib/features/spike_rastreo/domain/ruta_planificada.dart`: `llegada` es
el destino (la URBE, con la etiqueta «URBE») e `inicio` es la salida de
respaldo. Cambiar el destino es editar esas dos coordenadas. No es de ningún
usuario: lo que se manejó de verdad queda en `spike_recorridos`, con el
`conductor_id` de quien corrió la sesión.

La ruta la traza el **servidor público de OSRM** (`router.project-osrm.org`).
Es **solo para pruebas**: su política de uso no admite tráfico de producción.
El proveedor de rutas de Cupo sigue sin decidir (**DA-19**). Si OSRM no
responde, el recorrido se hace igual: el resultado sale sin la comparación
contra la ruta. En web, OSRM se llama con `fetch` del navegador (responde con
`Access-Control-Allow-Origin: *`).

**Por qué antes «el mapa no estaba en la URBE».** No pude ver la pantalla del
usuario, pero en el código había dos causas que lo explican. Primera: el mapa
encuadraba la ruta entera desde la Av. 61, que queda 2,3 km al este, y no la
URBE. Segunda: en el navegador, la consulta a OSRM usaba `dart:io`, que no
existe en web, así que la ruta nunca llegaba y quedaba solo el encuadre
genérico. Ahora la cámara arranca en la URBE, encuadra la salida real y la
URBE con margen, y OSRM se consulta con `fetch` en web. Una prueba de widget
verifica que las dos queden a la vista.

### 13.2.1 En vivo: lo que falta, el desvío y la llegada

- **La unidad** es una flecha orientada por su rumbo, y la **cámara la
  sigue**. Si arrastras el mapa deja de seguirla; los botones del mapa sirven
  para volver a seguirla, para encuadrar todo y (con la brújula) para volver
  al norte.
- **Panel:** «Faltan X km» hasta la URBE, la distancia recorrida, el tiempo y
  la velocidad actual. Lo que falta se mide **sobre la ruta**: la posición se
  proyecta sobre la línea y se cuenta lo que queda de ella. **No se muestra
  hora estimada de llegada**: está fuera del alcance (Cuadro 18 de la tesis).
- **Desvío:** si la unidad pasa más de **80 m** de la ruta durante **15 s o 3
  muestras seguidas**, la app pide a OSRM una ruta nueva desde donde está
  hasta la URBE (nunca más de una cada **30 s**), avisa «Ruta recalculada» y
  la guarda en `spike_rutas_recalculadas` con su hora.
- **Llegada:** a **100 m** de la URBE avisa «Llegaste a la URBE» (con una
  notificación si Cupo está minimizada) y ofrece terminar. **No termina
  sola**: termina la persona, ya estacionada. La simulación sí termina sola.

### 13.3 Qué mide `spike_reporte_ruta(sesion)`

Una sola fila. Cada muestra se clasifica en *Cupo a la vista* (`resumed` con
pantalla encendida), *minimizada* (`paused`/`hidden` con pantalla encendida) o
*pantalla apagada*, y el tiempo entre dos muestras se carga al estado de la
primera (si Android congela la app, el silencio cae donde estaba).

| Grupo | Columnas | Cómo se lee |
| --- | --- | --- |
| Recorrido | `duracion_s`, `distancia_m`, `velocidad_media_kmh`, `velocidad_max_gps_kmh`, `velocidad_max_traza_kmh` | Distancia = suma de `ST_Distance` entre muestras consecutivas. Las velocidades validan la traza: más de ~120 km/h en la ciudad delata saltos falsos. |
| Cobertura | `esperadas`, `recibidas`, `cobertura_pct` y, por estado, `pct_*` (parte del tiempo) y `cobertura_*` | Igual que en las fases, pero separada por lo que de verdad pasó. |
| Brechas | `brecha_max_s`, `brecha_max_en`, `brecha_max_m`, `brecha_p95_s`, `brechas_largas` | La brecha en **metros** es el salto más largo sin muestras: lo que el estudiante no vio moverse. |
| Entrega | `perdidas`, `tardias`, `latencia_mediana_s` | Como en las fases (sección 4.4). La marca de cierre tiene el `seq` siguiente, así que se ven también las perdidas justo antes de terminar. |
| Contra la ruta | `desvio_mediana_m`, `desvio_p95_m`, `desvio_max_m`, `pct_muestras_cerca_ruta` (≤ 50 m), `pct_ruta_cubierta`, `rutas_recalculadas` | Si el GPS siguió las calles. **Decisión:** cada muestra se mide contra la **ruta vigente cuando se capturó** (la última recalculada antes de esa hora, o la original); así, un desvío del chofer que ya provocó un recálculo no infla el desvío del resto del viaje. *Ruta cubierta* se mide contra la **última ruta vigente**, la que de verdad llevó a la URBE: la línea se parte en puntos cada ≤ 25 m y se cuentan los que tienen alguna muestra a ≤ 50 m. La ruta original queda en `spike_recorridos` y las recalculadas en `spike_rutas_recalculadas`, para compararlas en el mapa. |
| Simulación | `simulada` (primera columna) | `true` si la sesión la produjo el simulador: **no es evidencia**. |
| Teléfono | `precision_p50_m`, `precision_p95_m`, `pct_cargando`, `bateria_inicio_pct`, `bateria_fin_pct` | Si iba enchufado, el resultado no mide el peor caso: anótalo. |
| Domicilio de prueba | `dom_radio_m`, `dom_distancia_min_m`, `dom_entrada_en`, `dom_entrada_m`, `dom_brecha_previa_s`, `dom_muestras_alrededor`, `dom_aviso_a_tiempo` | Solo si se marcó uno. A qué hora y a cuántos metros la unidad entró por primera vez en el radio de **1500 m** (el aviso de proximidad de HU-014), cuánto silencio hubo justo antes (si fue largo, el aviso habría salido tarde) y cuántas muestras hubo en ±60 s. |
| Veredicto | `completa`, `cumple` | `completa` = se tocó «Terminar recorrido». |

### 13.4 Criterio de éxito del recorrido

> **Cumple** si el recorrido está completo y:
>
> - la cobertura es **≥ 90 %** con Cupo **minimizada** y con la **pantalla
>   apagada** (cada estado por separado, los que hubo), y
> - la brecha máxima es **≤ 30 s** y el salto máximo **≤ 500 m**.

500 m son unas cuatro cuadras: más que eso, la unidad «salta» en el mapa del
estudiante. Un recorrido que pasó menos de la mitad del tiempo fuera de la
vista no prueba el segundo plano aunque cumpla: la app lo avisa.

### 13.5 Preparación

1. **Instala el APK** y entra como conductor (sección 6.1). Comprueba que la
   prueba por fases arranca (el ensayo de 6 min basta): así sabes que los
   permisos y el envío funcionan antes de salir.
2. **Batería cargada.** Para medir el peor caso, haz la ruta **sin cargador**.
   Si va conectado al cargador del carro (lo realista), también vale: queda
   registrado en cada muestra (`cargando`) y en el resultado; anótalo en la
   tabla.
3. **Datos móviles encendidos** (en la calle no hay wifi).
4. Quién maneja: **idealmente uno de los choferes entrevistados, con su propio
   teléfono**. Es la evidencia más fuerte para el Cap. IV: su marca, su capa
   del fabricante, su forma de usar el teléfono.

### 13.6 Seguridad

- **Configura todo antes de arrancar**: elige el modo, revisa la ruta en el
  mapa, marca el domicilio de prueba si lo usarás y toca «Empezar recorrido»
  con el carro detenido.
- **Manejando, nadie toca el teléfono.** Si hace falta mirarlo, lo hace un
  acompañante. «Terminar recorrido» se toca **ya estacionado**; la app lo
  pregunta («¿Ya estacionaste?»).
- La prueba no necesita que nadie mire la pantalla: todo queda registrado.

### 13.7 Protocolo (unos 10 a 20 min)

1. Ve a donde empezará el recorrido. En «Prueba de rastreo», elige
   **Recorrido real**. Acepta el permiso de ubicación: el mapa pasa de la URBE
   a la ruta desde donde estás, con la distancia y las calles.
2. (Opcional) Toca «Domicilio de prueba» y luego el mapa, cerca de la ruta,
   para medir el aviso de proximidad. Se dibuja su radio de 1,5 km.
3. Con el carro detenido, toca **«Empezar recorrido»** y acepta los permisos.
   Espera «RECORRIDO REAL · EN CURSO».
4. **Primera mitad: con Cupo minimizada.** Toca Inicio y abre WhatsApp o Waze,
   como haría el chofer. Pantalla encendida.
5. **Segunda mitad: con la pantalla bloqueada.** A mitad de camino (si
   manejas tú, en un semáforo no: espera a un sitio donde puedas detenerte, o
   que lo haga el acompañante), bloquea el teléfono y no lo toques.
6. Al llegar, la app avisa «Llegaste a la URBE». **Estacionado**,
   desbloquea, abre Cupo y toca **«Terminar recorrido»** → «Terminar».
7. Lee el resultado y toca **«Ver mapa a pantalla completa»** para la figura
   (13.9). Copia el identificador de la sesión a la tabla.

No hace falta marcar en la app qué tramo fue cuál: el reporte separa el tiempo
por `estado_app` y `pantalla_encendida`, que se registran solos en cada
muestra. Si quieres más tiempo de cada estado, sal de más lejos o haz la ruta
dos veces (dos sesiones).

### 13.8 Repetir con otras marcas

Una corrida vale por un teléfono. Para la tesis conviene **al menos dos
marcas**, una de ellas Samsung, Xiaomi o Huawei (las de ahorro de batería
más agresivo, EA-18). Por cada teléfono: primero con la configuración de
fábrica; si no cumple, repite con la batería «Sin restricciones» y luego con
«Permitir todo el tiempo» (las mismas corridas A–C de la sección 6.4). Misma
ruta, a una hora de tráfico parecida.

### 13.9 La figura para el Cap. IV

- **Desde la app:** en el resultado, «Ver mapa a pantalla completa» abre el
  mapa con título (ruta, fecha, teléfono y cobertura) y leyenda: ruta
  planificada en tono suave, traza real en verde lago oscuro, **brechas en
  rojo punteado**, inicio, llegada, domicilio con su radio, flechas de
  sentido y el crédito «© OpenStreetMap contributors». Encuadra con dos dedos
  (o con el botón de encuadre) y toma una **captura de pantalla** (encendido
  + bajar volumen). El crédito de OpenStreetMap debe quedar visible en la
  figura.
- **Fuera de la app:** «Copiar GeoJSON» copia la sesión entera como GeoJSON.
  Pégalo en [geojson.io](https://geojson.io) o ábrelo en QGIS (Capa › Añadir
  capa vectorial, desde un archivo `.geojson`). También sale por SQL:

  ```sql
  select public.spike_ruta_geojson('PEGA-AQUÍ-EL-SESION-ID');
  ```

  En el SQL Editor, copia la celda del resultado y guárdala como
  `recorrido.geojson`. Cada elemento lleva `properties.tipo`:
  `ruta_planificada`, `traza`, `brecha` (con `segundos` y `metros`),
  `muestra` (con `seq`, hora, `estado_app`, `pantalla_encendida`,
  `precision_m`, `bateria_pct`, `cargando`, `rumbo_deg`, `velocidad_kmh`),
  `inicio_plan`, `llegada_plan` y `domicilio`. Coordenadas en [lng, lat].

### 13.10 Leer el recorrido en Supabase

```sql
-- Los recorridos, el más reciente primero
select r.sesion_id, r.creado_en, r.ida_y_vuelta,
       round(r.ruta_distancia_m) as ruta_m, s.dispositivo, s.muestras
  from public.spike_recorridos r
  join public.spike_sesiones s using (sesion_id)
 order by r.creado_en desc;

-- El resultado (una fila)
select * from public.spike_reporte_ruta('PEGA-AQUÍ-EL-SESION-ID');

-- Con otro domicilio de prueba, sin repetir el recorrido
select dom_entrada_en, dom_entrada_m, dom_brecha_previa_s, dom_aviso_a_tiempo
  from public.spike_reporte_ruta('PEGA-AQUÍ-EL-SESION-ID',
         'SRID=4326;POINT(-71.6235 10.7092)'::geography);
```

Para encontrar dónde ocurrió una brecha, la consulta «los diez silencios más
largos» de la sección 7 sirve igual (agrega `lat, lng` a sus columnas).

### 13.11 Tabla de resultados del recorrido

Una fila por recorrido.

| Fecha y hora | Chofer | Teléfono | Android / capa | Permiso | Batería de Cupo | ¿Enchufado? | Salida | Duración | Distancia | Cobertura minimizada | Cobertura pantalla apagada | Brecha máx. (s / m) | Desvío p95 | Ruta cubierta | Resultado | Sesión |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | min | km | % | % | s / m | m | % | | |
| | | | | | | | | min | km | % | % | s / m | m | % | | |

Junto a cada fila: la captura del mapa (13.9) y, si hubo brechas, en qué
calle ocurrieron.

## 14. Simulación

> **Una sesión simulada NUNCA cuenta como evidencia.** No la produjo ningún
> GPS ni la frenó ningún Android: sirve para ver la unidad moverse por el
> mapa y para probar de punta a punta la cola, el envío, el reporte SQL y la
> figura. Queda marcada en cada fila (`simulada = true`), en
> `spike_sesiones.simulada`, en la primera columna de `spike_reporte_ruta()`,
> en el GeoJSON y en la pantalla del resultado («SESIÓN SIMULADA»).

### 14.1 Verla en el navegador (localhost)

Desde `cupo/`:

```bash
flutter run -d chrome --dart-define-from-file=dart_define.json
```

Entra con el conductor de prueba, toca «Prueba de rastreo» y elige **Simular
recorrido**. En el navegador no hace falta teléfono, permiso de ubicación ni
servicio en primer plano; la batería y la pantalla quedan vacías (`null`),
porque ese canal solo existe en Android.

### 14.2 Qué hace

1. Usa el mismo plan del recorrido real: la ruta de OSRM hasta la URBE sobre
   el mapa (por omisión desde la salida de respaldo, la Av. 61; «Salir desde
   mi ubicación actual» la cambia) y el domicilio opcional.
2. Elige la **velocidad** (20, 30 o 50 km/h; 30 por omisión) y **qué tan
   rápido verla**: ×1 (tiempo real), ×5 o ×20. A ×20 y 30 km/h, los 5,4 km
   se ven en unos 32 s.
3. Opcional: **«Simular un corte de señal»** salta unos 60 s de muestras a
   mitad de ruta (sale en rojo en el resultado) y **«Simular un desvío»**
   lleva la unidad 45 s por una paralela a 150 m (dispara el recálculo).
4. «Empezar simulación»: la flecha avanza por las calles, la traza se dibuja
   detrás y la cámara la sigue. Al llegar termina sola y muestra el resultado
   normal (mapa, flechas, brechas y métricas).

Detalles: una muestra cada 5 s de **tiempo simulado** (a ×20 llegan cada
0,25 s, pero sus horas siguen separadas 5 s, así el reporte mide igual), con
el rumbo del tramo, un ruido de GPS de hasta ±7 m por eje y precisión de 8 m.
La lógica está en `domain/simulador.dart` (Dart puro, determinista con
semilla en las pruebas) y la fuente en `data/fuente_simulada.dart`. La
latencia del reporte no significa nada en una simulación (el reloj es
simulado).

### 14.3 En Android

Funciona igual con el teléfono quieto, desde el APK de debug. Ahí sí se leen
la batería y la pantalla.

## 15. La notificación de la prueba

Mientras corre cualquiera de los tres modos, la barra de notificaciones tiene
**una sola notificación fija** que muestra que la prueba sigue viva. Se
actualiza con cada hito (arranque, primera ubicación, cambio de fase) y, si
no, como mucho cada 5 s.

| Parte | Qué muestra |
| --- | --- |
| Título | «Prueba de rastreo en curso» (fases), «Recorrido a la URBE en curso» o «Simulación en curso». |
| Cronómetro | El tiempo desde que tocaste «Empezar». **Lo dibuja Android solo**: si avanza, el teléfono está bien; si la notificación entera desaparece, Android mató la prueba (ver sección 8). |
| Texto | «128 enviadas · 0 pendientes · última hace 5 s», y en el recorrido «· faltan 3,2 km». En fases empieza con «Fase 2 de 3 · minimiza la app». |
| Barra | En fases, el avance de la prueba completa; en el recorrido, lo recorrido sobre el total (recorrido + lo que falta). |
| Acción | «Abrir» lleva a la pantalla de la prueba. **No hay «Terminar»** en la notificación, a propósito: no se toca manejando. |

Qué significa cada estado del texto:

- **«Buscando señal GPS…»**: todavía no llega la primera ubicación.
- **«N enviadas · 0 pendientes · última hace 5 s»**: todo bien.
- **«⚠ 6 pendientes, sin conexión»**: el GPS sigue capturando pero no hay red;
  las muestras esperan en la cola y salen solas cuando vuelva.
- **«Sin ubicación hace 45 s»** (más de 30 s sin una muestra nueva): el GPS
  dejó de entregar posiciones. Con la pantalla apagada es justo el fallo que
  mide esta prueba; mira la sección 8.
- **La notificación desapareció**: Android cerró el servicio (o la app). Es un
  fallo de la prueba: anótalo con la hora.

Al terminar, la notificación en vivo se quita y queda un **resumen
descartable**: «Prueba terminada · 96 % · PASA» (o «NO PASA», o «resultado
parcial»; en la simulación, «Simulación terminada · … · no es evidencia»). En
fases, el porcentaje es el de la peor fase; en el recorrido, el de toda la
sesión.

Detalles técnicos:

- **No hay dos notificaciones.** geolocator muestra su propia notificación
  fija del servicio en primer plano, con el id 75415 y en un canal de
  importancia **NONE**, que por eso casi no se veía en la barra. La app
  publica la suya **con ese mismo id**: reemplaza la de geolocator y sigue
  siendo la del servicio, así que Android nunca lo deja sin notificación. Va
  en un canal propio de importancia baja, «Prueba de rastreo: estado en
  vivo»: se ve, pero no suena ni vibra en cada actualización. Los avisos de
  cambio de fase y de «Llegaste a la URBE» siguen sonando por su canal de
  siempre. Si se actualiza geolocator, hay que revisar que el id siga siendo
  el mismo (`GeolocatorLocationService.ONGOING_NOTIFICATION_ID`).
- En Android 14 o más nuevo, el sistema deja descartar incluso las
  notificaciones fijas. Si la descartas, vuelve con la siguiente
  actualización, y el servicio no se detiene por eso.
- Las actualizaciones salen de Dart por el canal `cupo/spike_rastreo`. Con la
  pantalla apagada deberían seguir llegando mientras geolocator entregue
  posiciones, porque eso mantiene vivo el isolate de Dart. **No está
  verificado en un teléfono todavía.** Justamente, si se congelan, eso
  también es evidencia.
- **En el navegador (localhost)** no hay barra de notificaciones: el mismo
  estado va en el título de la pestaña, por ejemplo «● 128 · 3,2 km · Cupo»
  (con «○» cuando lleva más de 30 s sin ubicación), y al terminar «✓ 99 % ·
  Cupo».

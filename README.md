# Cupo — sistema de gestión de cupos de transporte estudiantil

Repositorio de la tesis y de la aplicación que la acompaña: una app móvil que
conecta a estudiantes con transportistas para la reserva y el seguimiento de
cupos en rutas y turnos de transporte universitario.

Aquí conviven dos cosas que se tocan pero no se mezclan: **el documento de
tesis** (y su documentación derivada) y **el software** que constituye su
artefacto. La regla de convivencia es simple: la tesis define el alcance, el
software lo cumple, y cada pieza construida debe poder rastrearse hasta un
objetivo específico.

---

## Qué hace la aplicación

Tres actores, cada uno con su recorrido:

- **Estudiante** — marca dónde vive, busca turnos con cupo disponible según sus
  días y horario, se inscribe, confirma su semana y sigue el viaje en curso.
- **Transportista** — administra sus rutas, turnos y zonas de cobertura, ve la
  nómina del día, cobra y lleva la cuenta de cada pasajero.
- **Administrador** — aprueba registros y mantiene el catálogo del sistema.

La pieza técnicamente interesante — y la que sostiene la investigación — es el
**filtrado geográfico en cadena**: dado un domicilio, un turno y unos días,
determinar qué unidades pasan lo bastante cerca como para que caminar tenga
sentido. Eso implica punto en polígono para las zonas de cobertura, distancia
punto-polilínea para las rutas y consultas por radio con geohash en Firestore.

## Estructura del repositorio

```
.
├── cupo/          la aplicación Flutter (Android)
├── docs/
│   ├── tesis/     copias de lectura de los capítulos — NO se editan a mano
│   └── producto/  documentación viva del producto — aquí sí se escribe
├── originales/    los .docx/.pdf entregados a la universidad (fuente de verdad)
└── TODO.md        plan de trabajo por fases, de la 0 a la 6
```

La distinción entre `docs/tesis/` y `docs/producto/` es deliberada y está
explicada en el README de cada carpeta. En resumen: lo primero es material
derivado de `originales/` y se regenera; lo segundo se escribe a mano y se
versiona como cualquier fuente.

## Por dónde empezar

Depende de qué vengas a hacer.

**Si vienes a programar** → [`cupo/README.md`](cupo/README.md). Ahí está todo:
requisitos, creación del proyecto, configuración de Android y Firebase,
extensiones de VS Code, herramientas, qué estudiar antes de escribir código y
recursos para aprenderlo. El entorno de esta máquina ya está montado: lo que
quedó instalado, las desviaciones respecto de ese README y cómo levantar la app
están más abajo, en **Entorno de desarrollo** y **Cómo levantar la app**.

**Si vienes a escribir la tesis** → [`docs/tesis/PENDIENTES.md`](docs/tesis/PENDIENTES.md).
Hay 31 pendientes abiertos, 7 de ellos bloqueantes.

**Si no sabes qué sigue** → [`TODO.md`](TODO.md). Las fases están ordenadas por
dependencia, no por gusto.

## Entorno de desarrollo

Los pasos 1 a 8 de [`cupo/README.md`](cupo/README.md) están ejecutados y
verificados en esta máquina.

### Qué quedó instalado

| Herramienta | Versión | Dónde |
|---|---|---|
| Flutter (canal stable) | 3.47.2 · Dart 3.13.2 | `C:\srclutter` |
| JDK Temurin | 17.0.20.1 | `%ProgramFiles%\Eclipse Adoptium` |
| Android SDK | ver abajo | `%LOCALAPPDATA%\Android\Sdk` |
| FlutterFire CLI | 1.4.1 | caché de Pub |
| Firebase CLI | 15.29.0 | npm global |
| scrcpy · Bruno | — | winget |

Del Android SDK: `platforms` 35 y 36, `build-tools` 35.0.0, `platform-tools`
37.0.1, NDK 28.2.13676358 y CMake 3.22.1. No hay Android Studio y no hace
falta: bastan los `cmdline-tools`.

Las siete extensiones de VS Code que el README de la app marca como
imprescindibles y recomendadas también están instaladas.

### Variables de entorno

Fijadas a nivel de usuario:

- `JAVA_HOME` → el JDK 17 de la tabla
- `ANDROID_HOME` y `ANDROID_SDK_ROOT` → `%LOCALAPPDATA%\Android\Sdk`
- En el `PATH`: `C:\srclutterin`, `platform-tools`,
  `cmdline-tools\latestin` y `%LOCALAPPDATA%\Pub\Cachein`

Después de tocarlas hay que **abrir una terminal nueva**: las ya abiertas
conservan el `PATH` viejo.

### Cómo comprobar que el entorno sigue sano

```powershell
cd cupo
flutter analyze          # sin issues
flutter test             # en verde
flutter build apk --debug
```

El último comando es la prueba real: ejercita Gradle, el SDK, el NDK y las
licencias. El APK resultante declara `com.cupo.app`, `minSdkVersion 26`,
`targetSdkVersion 35` y los siete permisos del manifest.

### Desviaciones respecto de `cupo/README.md`

Tres cosas de ese README no sobrevivieron al contacto con las versiones
actuales de las herramientas. Conviene corregirlas allí para que el documento y
el código no se contradigan ante el jurado.

1. **`compileSdk` es 36, no 35.** No es opcional: `firebase_*`,
   `sqflite_android` y `package_info_plus` exigen compilar contra 36, y el
   build falla contra 35. `minSdk = 26` (RNF-01) y `targetSdk = 35` quedan
   intactos: son independientes de `compileSdk`, que solo habilita APIs nuevas
   sin cambiar el comportamiento en ejecución.

2. **`sdkmanager "paquete;version"` ya no funciona.** Google lo deprecó y ahora
   delega en un CLI `android` con otra sintaxis, con `/` en vez de `;`:
   `android sdk install platforms/android-36`. Por lo mismo hubo que instalar
   el NDK a mano —el plugin de Gradle intentaba auto-instalarlo por la vía
   vieja y fallaba.

3. **`flutter doctor` marca dos avisos esperados.** "Android license status
   unknown" es cosmético: el CLI nuevo acepta las licencias al instalar, pero
   el chequeo de Flutter no sabe leerlo; el build real las acepta sin problema.
   El de Visual Studio es para apps de escritorio de Windows, no de Android.

## Cómo levantar la app

En un **teléfono físico**, no en el emulador. El emulador simula mal el GPS y no
reproduce las restricciones de batería del fabricante, que son justamente el
riesgo del Spike 1.

### Preparar el teléfono

1. **Ajustes → Acerca del dispositivo → Versión** → tocar siete veces sobre
   **Número de compilación**. Aparecen las Opciones de desarrollador.
2. **Ajustes → Ajustes adicionales → Opciones de desarrollador** → activar
   **Depuración por USB**. En ColorOS (Oppo/Realme) hace falta además
   **Desactivar monitoreo de permisos**, o se bloquea la instalación del APK.
3. Conectar el cable y elegir **Transferencia de archivos (MTP)** en la
   notificación de USB. En "Solo carga" la depuración no funciona.
4. Aceptar el diálogo *"¿Permitir depuración USB?"* y marcar **Siempre permitir
   desde este equipo**.

### Ejecutar

```powershell
cd cupo
adb devices     # el teléfono debe aparecer como "device"
flutter run
```

Desde VS Code es equivalente: **F5**, con el dispositivo elegido en la barra de
estado.

### Mientras corre

`flutter run` deja la terminal viva:

| Tecla | Qué hace |
|---|---|
| `r` | hot reload — aplica los cambios sin perder el estado de pantalla |
| `R` | hot restart — reinicia la app desde cero |
| `v` | abre DevTools (inspector de widgets, profiler) |
| `q` | salir |

### Si el teléfono no aparece

| Síntoma | Causa habitual |
|---|---|
| `adb devices` vacío | Depuración por USB sin activar, o cable de solo carga |
| `unauthorized` | Falta aceptar la huella RSA en la pantalla del teléfono |
| `offline` | Desconectar y volver a conectar |
| Windows lo ve, `adb` no | Está en MTP sin depuración: revisar el paso 2 |

`adb kill-server` seguido de `adb start-server` resuelve buena parte de los
casos raros.

## Estado actual

El proyecto está en la **Fase 0**: decisiones abiertas. El entorno de desarrollo
ya está montado y el esqueleto de la app existe —compila, corre y pasa sus
pruebas—, pero no implementa todavía ninguna funcionalidad del producto.

Tres cosas bloquean el avance ahora mismo:

1. **Faltan los originales de la tesis.** No hay carpeta `originales/`, y sin
   ella no se puede generar ninguna copia de lectura ni citar el Capítulo I,
   que es donde viven los objetivos específicos que definen el alcance.
2. **Hay decisiones de producto sin cerrar** que cambian el modelo de datos:
   Google Maps SDK contra OSM, si se admiten carros por puesto, cómo se comparte
   un puesto entre días alternos, y el plazo de vencimiento del estado
   "reservado". Están listadas en [`TODO.md`](TODO.md).
3. **El trabajo de campo no se ha aplicado.** Las entrevistas a transportistas y
   el cuestionario a estudiantes van **antes** del modelo de datos. Si la base de
   datos se diseña primero, los requerimientos quedan justificados al revés y
   eso se nota en la defensa.

## Lo esencial, en cuatro puntos

Si solo te llevas cuatro cosas de este README, que sean estas.

1. **El orden de las fases no es negociable.** Campo → requerimientos → diseño →
   construcción. Saltárselo produce un software que quizá funciona, pero cuya
   justificación metodológica no se sostiene.

2. **El Spike 1 va primero, y va esta semana.** Rastrear la ubicación con la app
   minimizada y la pantalla apagada es el riesgo que puede tumbar la
   arquitectura completa. Se prueba en un teléfono físico, no en el emulador.
   Si no funciona como se espera, es mejor saberlo ahora que en la Iteración 5.

3. **Lo que se puede probar sin interfaz, se prueba sin interfaz.** Los cálculos
   geométricos son Dart puro y viven en `cupo/lib/core/geo/`. Sus pruebas
   unitarias son evidencia directa para el Objetivo 4, y cuestan mucho menos que
   evaluar lo mismo a través de la app.

4. **Dos proyectos de Firebase, siempre: desarrollo y demostración.** Y ningún
   secreto en el repositorio: `google-services.json`, `firebase_options.dart`,
   los keystores y los `.env` ya están en el [`.gitignore`](.gitignore), y los
   entornos de Bruno en [`cupo/.gitignore`](cupo/.gitignore), donde vivirá la
   colección.

## Stack

| Capa | Elección |
|---|---|
| App | Flutter · Android · `minSdk 26` (RNF-01) · package `com.cupo.app` |
| Autenticación | Firebase Auth |
| Datos | Cloud Firestore |
| Posiciones en vivo | Firebase Realtime Database |
| Notificaciones | Firebase Cloud Messaging |
| Mapas | por decidir — Google Maps SDK u OSM con `flutter_map` (Fase 0) |
| Metodología | XP — iteraciones que cierran con algo funcionando y probado |

## Convenciones

- La documentación se escribe en español, en markdown, con líneas a 80
  columnas.
- Los documentos de `docs/producto/` citan los objetivos específicos por su
  numeración original del Capítulo I.
- Cada iteración de la Fase 5 cierra con algo que funciona y está probado. Una
  iteración que no corre en un teléfono no está cerrada.

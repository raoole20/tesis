# Cupo — aplicación móvil

Aplicación Flutter para Android del sistema de gestión de cupos de transporte
estudiantil. Es el artefacto de software de la tesis: cubre los objetivos
específicos 3, 4 y 5 (diseño lógico y físico, verificación y manual de usuario).

- Package: `com.cupo.app`
- Plataforma: Android únicamente (`minSdk 26`, RNF-01)
- Backend: Firebase (Auth, Firestore, Realtime Database, Cloud Messaging)
- Documentación viva del producto: [`../docs/producto/`](../docs/producto/)
- Plan de trabajo: [`../TODO.md`](../TODO.md)

> Esta carpeta contiene por ahora solo este README. El proyecto Flutter se
> genera dentro de ella con el paso 2; `flutter create` completa una carpeta
> existente sin borrar lo que ya está.

---

## 1. Requisitos previos

```bash
flutter --version        # canal stable actual (~3.47)
java -version            # JDK 17
flutter doctor -v
```

No hace falta Android Studio. Basta con los `cmdline-tools` del Android SDK y
apuntar Flutter hacia él:

```bash
flutter config --android-sdk /ruta/al/android-sdk
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
sdkmanager --licenses
```

`flutter doctor` va a marcar la ausencia de Android Studio. Es esperado y no
bloquea la compilación.

## 2. Crear el proyecto

```bash
flutter create --org com.cupo --project-name cupo \
  --platforms=android --empty .
```

- `--org com.cupo` fija el package `com.cupo.cupo`, porque Flutter compone el
  `applicationId` como `<org>.<project-name>`. En el paso siguiente se corrige a
  **`com.cupo.app`**, que es el identificador definitivo. El default es
  `com.example`, y ese sí no puede quedarse: Play Store lo rechaza.
- El nombre del paquete Dart sigue siendo `cupo` (los imports quedan como
  `package:cupo/...`), independiente del `applicationId` de Android.
- `--platforms=android` evita generar iOS, web y desktop. Se puede agregar iOS
  más adelante con `flutter create --platforms=ios .`.
- `--empty` entrega un `main.dart` limpio, sin el contador de demostración.

## 3. Configurar Android

`android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
    defaultConfig {
        applicationId = "com.cupo.app"
        minSdk = 26        // Android 8.0 — RNF-01
        targetSdk = 35
    }
}
```

El `applicationId` es la identidad definitiva de la app y **no se puede cambiar
después de publicar**. Hay que fijarlo aquí, antes de conectar Firebase: el
`google-services.json` se genera contra ese identificador y si luego no coincide,
la app no autentica.

`minSdk = 26` no es arbitrario: es el requisito no funcional declarado en la
tesis. Debe quedar explícito y coherente con el documento.

Permisos en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

`ACCESS_BACKGROUND_LOCATION` es el permiso crítico y el más difícil de manejar:
Android lo solicita en un diálogo aparte, después de conceder el permiso normal
de ubicación. Es exactamente lo que debe validar el **Spike 1**.

## 4. Estructura de carpetas

Organización por funcionalidad, no por tipo de archivo. Con capas técnicas
(`models/`, `screens/`, `widgets/`) se termina saltando entre cinco carpetas
para tocar una sola pantalla.

```
lib/
  main.dart
  core/
    config/          constantes, radio peatonal, umbrales
    theme/           tipografía, paleta, colores de estado del cupo
    geo/             punto en polígono, distancia punto-polilínea
    services/        firebase, notificaciones, ubicación
  features/
    auth/
    onboarding/      pin de casa, zona detectada
    search/          días y turno, resultados, detalle
    enrollment/      inscripción, mi semana, lista de espera
    trip/            viaje en curso, seguimiento
    account/         cargos, abonos, saldo
    driver/          hoy, semana, rutas, cobros
  shared/
    models/          entidades compartidas
    widgets/
```

Los cálculos de `core/geo/` son Dart puro, sin dependencias de Flutter ni de
Firebase. Eso permite cubrirlos con pruebas unitarias, y esas pruebas son
evidencia directa para el Objetivo 4.

## 5. Dependencias

```bash
flutter pub add firebase_core firebase_auth cloud_firestore \
  firebase_database firebase_messaging
flutter pub add geolocator flutter_map latlong2 sqflite intl
flutter pub add --dev flutter_lints test
```

Quedan fuera por ahora `flutter_background_geolocation` y
`geoflutterfire_plus`: se agregan cuando lleguen los spikes que los necesitan,
no antes.

## 6. Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<tu-proyecto-firebase>
```

Genera `lib/firebase_options.dart` y `android/app/google-services.json`.
Ninguno de los dos va al repositorio.

Conviene crear **dos proyectos** en la consola de Firebase: uno de desarrollo y
otro para la demostración final. No se quiere estar borrando datos de prueba la
noche antes de la defensa.

## 7. Higiene inicial

`analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
```

`.gitignore` (además de lo que genera Flutter):

```
android/app/google-services.json
lib/firebase_options.dart
*.jks
key.properties
.env
```

## 8. Verificar antes de escribir código

```bash
flutter analyze
flutter test
flutter run -d <tu-teléfono>
```

Si la app vacía compila y corre en un teléfono físico, el entorno está listo.
Ese es el commit inicial.

---

## Qué estudiar antes de tirar código

El orden importa: cada bloque se apoya en el anterior. No hace falta dominar
todo, sí reconocer los conceptos cuando aparezcan en un error.

### 1. Dart (2–3 días)

Sin esto, todo lo demás se lee como magia.

- Tipado sano: `late`, `final` vs `const`, genéricos.
- **Null safety**: `?`, `!`, `??`, `?.`. Es la fuente número uno de errores de
  compilación al empezar.
- Asincronía: `Future`, `async`/`await`, `Stream`, `StreamBuilder`. Firestore y
  la ubicación son streams; sin entender streams no se avanza.
- Clases: constructores nombrados, `factory`, `copyWith`, `fromJson`/`toJson`.

### 2. Flutter — fundamentos (3–5 días)

- **Todo es un widget**, y la diferencia entre `StatelessWidget` y
  `StatefulWidget`.
- El árbol de widgets y por qué `build` se vuelve a ejecutar.
- Layout: `Column`, `Row`, `Expanded`, `Flexible`, `Stack`, `Padding`,
  `SizedBox`. Vale la pena entender **cómo funcionan las restricciones**
  (constraints go down, sizes go up): evita la mitad de los errores de layout.
- Listas: `ListView.builder`, `ListView.separated`, scroll.
- Navegación: rutas nombradas o `go_router`, y paso de argumentos.
- `Theme`, `TextTheme`, `ColorScheme`: la base del sistema de diseño de la
  Fase 4.
- Formularios: `Form`, `TextFormField`, validación.

### 3. Manejo de estado (2 días)

Antes de elegir librería, entender **por qué** hace falta: `setState` no
alcanza cuando dos pantallas comparten datos.

- `setState` y sus límites.
- `InheritedWidget` en concepto (no hay que escribirlo a mano).
- Elegir **una** solución y quedarse con ella: `provider` o `riverpod` son
  suficientes para este proyecto. No hace falta BLoC.

Decidirlo antes de la Iteración 1 y dejarlo escrito en `docs/producto/`.
Cambiar de manejo de estado a mitad del proyecto cuesta días.

### 4. Firebase (3–4 días)

- Modelo de datos de **Firestore**: colecciones, documentos, subcolecciones. No
  es SQL; la desnormalización es normal y esperada.
- Consultas y sus límites: índices compuestos, por qué no existe el `JOIN`, por
  qué algunas queries fallan hasta crear el índice.
- **Reglas de seguridad**. Es lo que un jurado puede preguntar y lo que casi
  nadie estudia.
- `firebase_auth`: registro, sesión, estado de autenticación como stream.
- Diferencia entre **Firestore** (datos persistentes) y **Realtime Database**
  (posiciones en vivo). Aquí se usan las dos, cada una para lo suyo.
- Cloud Messaging: notificaciones en primer plano vs segundo plano.

### 5. Android: permisos y ciclo de vida (2 días)

Es donde el proyecto puede romperse, así que no conviene improvisarlo.

- Permisos en tiempo de ejecución y el flujo de dos pasos de la ubicación en
  segundo plano.
- **Foreground services** y por qué son obligatorios para rastrear ubicación con
  la pantalla apagada.
- Optimización de batería y restricciones por fabricante (Xiaomi, Huawei y
  Samsung matan servicios en segundo plano de forma agresiva). Esto puede
  aparecer como una limitación legítima en el capítulo de resultados.

### 6. Geo (2 días)

- Coordenadas, latitud/longitud, la fórmula de Haversine.
- **Geohash**: qué es y por qué permite consultas por radio en Firestore.
- Algoritmo de **punto en polígono** (ray casting).
- Distancia de un punto a una polilínea (proyección sobre segmento).

Estos cuatro son el Spike 3 y son Dart puro: se pueden estudiar y probar sin
tocar la interfaz.

### 7. Pruebas (1 día)

- `test` para lógica pura (los cálculos de `core/geo/`).
- `flutter_test` con `testWidgets` para lo visual.
- Escribir primero las pruebas de geometría: son el mejor ejemplo de TDD del
  proyecto y evidencia lista para el Objetivo 4.

### Lo que conviene NO estudiar todavía

Animaciones avanzadas, `CustomPainter`, código nativo con platform channels,
CI/CD, publicación en Play Store, arquitectura limpia con tres capas y cuatro
abstracciones. Nada de eso está en el alcance y consume el tiempo que hace falta
en los spikes.

---

## Recursos

### Dart

| Recurso | Por qué |
|---|---|
| [Dart Language Tour](https://dart.dev/language) | La referencia oficial. Se lee de corrido en unas horas. |
| [Dart Cheatsheet interactivo](https://dart.dev/codelabs/dart-cheatsheet) | Ejercicios en el navegador, sin instalar nada. |
| [Understanding null safety](https://dart.dev/null-safety/understanding-null-safety) | El mejor texto sobre el tema. |
| [Async programming: futures, async, await](https://dart.dev/codelabs/async-await) | Codelab oficial de asincronía. |

### Flutter

| Recurso | Por qué |
|---|---|
| [Flutter — Get started codelab](https://docs.flutter.dev/get-started/codelab) | Primera app guiada. |
| [Flutter Widget of the Week (YouTube)](https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG) | Videos de 1–3 min por widget. Ideal para ratos muertos. |
| [Layouts in Flutter](https://docs.flutter.dev/ui/layout) | Guía visual de layout. |
| [Understanding constraints](https://docs.flutter.dev/ui/layout/constraints) | Explica el 80 % de los errores de layout. |
| [Flutter Cookbook](https://docs.flutter.dev/cookbook) | Recetas cortas: formularios, listas, navegación, red. |
| [Material 3 en Flutter](https://docs.flutter.dev/ui/design/material) | Base del sistema de diseño de la Fase 4. |
| [DartPad](https://dartpad.dev) | Probar ideas sin crear proyecto. |

### Manejo de estado

| Recurso | Por qué |
|---|---|
| [State management — docs oficiales](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | Explica el problema antes que las librerías. |
| [Simple app state management (provider)](https://docs.flutter.dev/data-and-backend/state-mgmt/simple) | Suficiente para este proyecto. |
| [Riverpod](https://riverpod.dev) | Alternativa, si se prefiere sobre provider. |

### Firebase

| Recurso | Por qué |
|---|---|
| [FlutterFire](https://firebase.flutter.dev) | Configuración e integración por paquete. |
| [Get to know Cloud Firestore (YouTube)](https://www.youtube.com/playlist?list=PLl-K7zZEsYLluG5MCVEzXAQ7ACZBCuZgZ) | La mejor explicación del modelo de datos NoSQL. |
| [Firestore data model](https://firebase.google.com/docs/firestore/data-model) | Referencia de colecciones y documentos. |
| [Firestore security rules](https://firebase.google.com/docs/firestore/security/get-started) | Obligatorio antes de la Fase 3. |
| [Structure your data (Realtime DB)](https://firebase.google.com/docs/database/web/structure-data) | Para decidir qué va en RTDB. |
| [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite) | Probar reglas y consultas sin gastar cuota ni ensuciar datos. |

### Android, ubicación y permisos

| Recurso | Por qué |
|---|---|
| [Request location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions) | El flujo de dos pasos del permiso en segundo plano. |
| [Foreground services](https://developer.android.com/develop/background-work/services/foreground-services) | Requisito para el rastreo con pantalla apagada. |
| [geolocator — pub.dev](https://pub.dev/packages/geolocator) | El README del paquete es la mejor documentación práctica. |
| [dontkillmyapp.com](https://dontkillmyapp.com) | Qué hace cada fabricante contra los servicios en segundo plano. |

### Geo

| Recurso | Por qué |
|---|---|
| [Movable Type — cálculos con lat/long](https://www.movable-type.co.uk/scripts/latlong.html) | Haversine y afines, con fórmulas y código. |
| [Geoqueries en Firestore](https://firebase.google.com/docs/firestore/solutions/geoqueries) | Consultas por radio con geohash, explicado por Google. |
| [Point in polygon (W. R. Franklin)](https://wrfranklin.org/Research/Short_Notes/pnpoly.html) | Ray casting en su versión canónica. |
| [flutter_map](https://docs.fleaflet.dev) | Mapas con OSM, si se descarta Google Maps SDK. |

### Para dudas del día a día

- Flutter Community en Discord y r/FlutterDev.
- [Stack Overflow — tag `flutter`](https://stackoverflow.com/questions/tagged/flutter).
- `pub.dev`: antes de instalar un paquete, mirar fecha de última publicación,
  likes y si soporta la versión de Flutter en uso.

---

## Orden sugerido de arranque

1. Estudiar Dart y los fundamentos de Flutter (bloques 1 y 2).
2. Montar el entorno y llegar al commit inicial (pasos 1 a 8).
3. **Spike 1** — ubicación en segundo plano. Es el que puede tumbar la
   arquitectura; hacerlo temprano.
4. Estudiar Firestore y hacer los Spikes 2 y 3.
5. Recién ahí, empezar la Iteración 1.

El detalle de fases y entregables está en [`../TODO.md`](../TODO.md).

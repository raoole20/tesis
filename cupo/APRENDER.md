# Qué estudiar antes de tirar código

Este archivo salió del README de la app para que instalar y correr el
proyecto no obligue a leer 200 líneas de plan de estudio. Es material de
aprendizaje, no de instalación.

---

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

### 4. Supabase (3–4 días)

- **Postgres**, no NoSQL: tablas, claves foráneas, `JOIN`, tipos `enum`. El
  modelo está normalizado y las migraciones viven en `supabase/migrations/`.
- **RLS (Row Level Security)**. Es lo que un jurado puede preguntar y lo que
  casi nadie estudia: cada tabla decide, por fila, quién la ve y quién la
  escribe.
- `supabase_flutter`: registro, sesión, `onAuthStateChange` como stream.
- **Realtime**: suscribirse a los cambios de una fila o una tabla. Es lo que
  hace que la pantalla del usuario cambie sola cuando cambia su estado.
- Triggers y funciones en PL/pgSQL: `crear_usuario()` y `detectar_zona()` ya
  están escritos; conviene poder leerlos.
- Notificaciones: Supabase no envía push. Cómo avisar al usuario (Realtime
  más notificaciones locales, u otro servicio) se decide en la Iteración 5.

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

### Supabase

| Recurso | Por qué |
|---|---|
| [supabase_flutter](https://supabase.com/docs/reference/dart/introduction) | Referencia del cliente Dart: auth, consultas, realtime. |
| [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) | Obligatorio antes de la Fase 3. |
| [Auth con Flutter](https://supabase.com/docs/guides/auth/quickstarts/flutter) | Registro, sesión y OAuth con deep links. |
| [Realtime](https://supabase.com/docs/guides/realtime) | Suscripciones a cambios de filas. |
| [Migraciones y CLI local](https://supabase.com/docs/guides/local-development) | Aplicar el esquema y probar sin tocar el proyecto real. |
| [PostgreSQL Tutorial](https://www.postgresqltutorial.com) | Si el SQL está oxidado. |

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
2. Montar el entorno siguiendo la [instalación](README.md#instalación).
3. **Spike 1** — ubicación en segundo plano. Es el que puede tumbar la
   arquitectura; hacerlo temprano.
4. Estudiar Postgres y RLS, y hacer los Spikes 2 y 3.
5. Recién ahí, empezar la Iteración 1.

El detalle de fases y entregables está en [`../TODO.md`](../TODO.md).

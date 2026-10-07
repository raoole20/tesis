# Buenas prácticas de Flutter y Dart — lista de revisión

Lo que `flutter analyze` no atrapa, ajustado al stack de Cupo (Material 3,
Supabase, `InheritedWidget`, geolocator, flutter_map, sqflite). Cada punto dice
qué buscar y por qué. Revisa solo las secciones que toque el cambio.

## Índice

1. [Ciclo de vida y recursos](#1-ciclo-de-vida-y-recursos)
2. [Async y BuildContext](#2-async-y-buildcontext)
3. [Estado](#3-estado)
4. [Construcción de widgets y rendimiento](#4-construcción-de-widgets-y-rendimiento)
5. [Layout y tamaños de pantalla](#5-layout-y-tamaños-de-pantalla)
6. [Accesibilidad](#6-accesibilidad)
7. [Formularios](#7-formularios)
8. [Dart](#8-dart)
9. [Pruebas](#9-pruebas)
10. [Plataforma: ubicación, mapas, almacenamiento](#10-plataforma-ubicación-mapas-almacenamiento)

## 1. Ciclo de vida y recursos

- Todo lo que el `State` crea, el `State` lo libera en `dispose()`:
  `TextEditingController`, `FocusNode`, `ScrollController`, `PageController`,
  `AnimationController` → `dispose()`; `StreamSubscription`, `Timer` →
  `cancel()`; `StreamController` → `close()`. Si no, sigue vivo y escuchando
  después de cerrar la pantalla (fuga y, a veces, `setState` sobre un widget
  muerto).
- Lo que llega desde el padre por constructor **no** lo libera el hijo.
- Se crean como campo o en `initState`, nunca en `build` (se recrearían en
  cada reconstrucción y perderían el texto o la posición).
- `super.initState()` va primero; `super.dispose()` va al final.
- `AnimationController` necesita `SingleTickerProviderStateMixin` (o
  `TickerProviderStateMixin` si hay varios).
- Si el `State` copia un parámetro del widget (`late _rol = widget.rolInicial`),
  piensa si hace falta `didUpdateWidget` para cuando el padre cambie ese valor.
  Si es intencional que solo se lea al inicio, está bien.
- `dependOnInheritedWidgetOfExactType` (y por tanto `AuthScope.de`,
  `Theme.of`, `MediaQuery.*Of`) no se llama en `initState`: va en `build`,
  `didChangeDependencies` o en un callback.

## 2. Async y BuildContext

- Después de un `await`, el widget puede ya no existir. Antes de `setState`,
  `Navigator.of(context)`, `ScaffoldMessenger.of(context)` o cualquier uso de
  `context`, va `if (!mounted) return;`. El lint
  `use_build_context_synchronously` cubre parte del `context`, pero no todos
  los `setState`.
- Lo que se necesite del `context` se captura **antes** del `await`
  (`final repo = AuthScope.de(context).repositorio;`), como hace
  `SignUpScreen`.
- Patrón del repo para enviar: validar → `setState(_enviando = true)` →
  `try { await … } on AuthFallo catch (e) { if (mounted) setState(…) }
  finally { if (mounted) setState(() => _enviando = false); }`.
- Mientras se envía, el botón queda deshabilitado (`onPressed: null` +
  `isLoading: true`): evita el doble envío.
- Atrapa tipos concretos (`on AuthFallo`, `on PostgrestException`). Un
  `catch (e)` genérico que termina en pantalla como `e.toString()` le muestra a
  la persona un mensaje técnico en inglés.
- Un `catch` vacío o un `onError: (_) {}` necesita un comentario que diga por
  qué tragarse el error es correcto (como el de Realtime en `AuthGate`).
- Futures que a propósito no se esperan: `unawaited(...)` o `.ignore()`, con
  un comentario (como `registrar_acceso` en `AuthRepository.entrar`).
- El callback de `setState` es síncrono y corto: nada de `await` adentro ni
  trabajo pesado.
- `FutureBuilder`/`StreamBuilder` reciben un Future/Stream creado en
  `initState` y guardado en un campo; creado en `build`, la consulta se relanza
  en cada reconstrucción.
- Navegar después de un login no hace falta: `AuthGate` escucha la sesión y
  enruta. Un `Navigator.push` tras `entrar()`/`registrar()` es sospechoso.

## 3. Estado

- `setState` envuelve solo el cambio de campos; lo derivado se calcula en
  `build` en vez de guardarse duplicado.
- Estado compartido entre pantallas: `AuthScope` hoy. Si el cambio necesita
  más (varias pantallas observando lo mismo, invalidación fina), es momento de
  la decisión de manejo de estado; no se improvisa con singletons globales ni
  variables estáticas mutables.
- `updateShouldNotify` compara lo que de verdad cambia.
- Listas con elementos que tienen estado o se reordenan llevan `key`
  (`ValueKey(id)`); sin key, el estado se queda pegado a la posición.

## 4. Construcción de widgets y rendimiento

- `const` en constructores y en instancias siempre que se pueda
  (`const SizedBox(height: AppSpacing.md)`): Flutter se salta esos subárboles
  al reconstruir.
- Un `build` largo se parte en widgets privados (`class _Encabezado extends
  StatelessWidget`) cuando la pieza tiene estado propio, se reutiliza o es
  costosa. Un método auxiliar es aceptable para una bifurcación simple (como
  `AuthGate._contenido()`).
- Nada de trabajo pesado en `build`: parsear, ordenar listas grandes, compilar
  `RegExp`, leer disco o red.
- Listas largas o de tamaño desconocido: `ListView.builder`/`.separated`. Evita
  `shrinkWrap: true` y `Column` dentro de `SingleChildScrollView` para listas
  que crecen; evita dos scrolls en el mismo eje.
- `MediaQuery.sizeOf(context)`, `paddingOf`, `viewInsetsOf`, `textScalerOf`
  en vez de `MediaQuery.of(context).size`: reconstruyen solo si cambia ese
  dato.
- `Theme.of(context)` una vez por `build`, en una variable local, si se usa
  varias veces.
- `Container` solo para padding o color → `Padding`, `ColoredBox` o
  `DecoratedBox`.
- `Opacity` animada → `FadeTransition`/`AnimatedOpacity`. Una `Opacity` fija
  (como la del botón deshabilitado) está bien.
- Imágenes de red grandes: `cacheWidth`/`cacheHeight`.

## 5. Layout y tamaños de pantalla

- El lienzo de diseño es 390×844, pero la app tiene que funcionar en 360×640 y
  con texto ampliado (escala 1.3 o más) sin `RenderFlex overflowed`. El
  español es más largo que el inglés: los rótulos crecen.
- Las pantallas usan `CupoScreen` (área segura, margen lateral, contenido
  desplazable y pie anclado). Si una pantalla no lo usa, tiene que resolver
  ella misma el área segura y el teclado.
- `Expanded`/`Flexible` solo dentro de `Row`/`Column`/`Flex`, y nunca dentro de
  algo desplazable en el mismo eje.
- Texto en un ancho acotado: `maxLines` + `overflow`, o `Flexible`. Nada de
  anchos fijos para contenedores de texto.
- Contenido que puede quedar bajo el teclado: dentro de algo desplazable.

## 6. Accesibilidad

- Área táctil mínima 48×48 dp. `AppSizes.iconButton` mide 44: si se crea otro
  control de ese tamaño, compensa con relleno o `materialTapTargetSize`.
- Controles con solo un icono necesitan etiqueta: `tooltip` en `IconButton`,
  `Semantics(label: 'Volver', button: true, …)` o `Icon(semanticLabel: …)`.
  `CupoBackButton` hoy no la tiene.
- Imágenes: `semanticLabel`, o `excludeFromSemantics: true` si son
  decorativas.
- Contraste aproximado sobre blanco: `ink`, `textSecondary` (≈5.6:1) y
  `primary` (≈4.9:1) pasan AA; `textSupport` (≈3.8:1), `textSupportSoft`
  (≈3.1:1), `success` (≈3.4:1) y `warning` (≈3:1) no, para texto pequeño.
  Esos tonos son para hints, texto grande/negrita, iconos y bordes, no para
  información imprescindible en 12–14 px.
- Ningún estado solo por color (ver R7).
- No bloquear el escalado de texto (`textScaler: TextScaler.noScaling`) salvo
  en piezas gráficas de tamaño fijo muy justificadas, y con un comentario que
  diga por qué.

## 7. Formularios

- Cada campo con su etiqueta visible (`CupoField(label: …)`), `keyboardType`
  correcto, `textInputAction` (`next` y `done` en el último), `autofillHints`
  y `textCapitalization` cuando aplique (nombres → `words`, cédula →
  `characters`).
- `onSubmitted` del último campo dispara la acción principal.
- Validación con mensajes concretos en español que dicen qué hacer; el error
  se muestra con `CupoErrorBanner`.
- Lo que se escribe se recorta (`trim()`) antes de guardarlo; el repositorio ya
  lo hace con lo que envía.
- Claves: `CupoPasswordInput` (trae `AutofillHints.password` por defecto); al
  registrar se le pasa `AutofillHints.newPassword`.

## 8. Dart

- Null safety: evita `!`. Copia a una variable local `final` para que Dart
  promueva el tipo (patrón de `AuthGate._contenido` y
  `AuthRepository.cargarUsuarioActual`). `late` solo si la inicialización
  está garantizada antes del primer uso.
- `strict-casts` está activo: el JSON de Supabase llega como
  `Map<String, dynamic>` y cada campo se convierte explícito
  (`fila['email'] as String`) dentro de un `fromMap` en `domain/`.
- `switch` sobre enums sin `default`, con expresiones `switch` cuando
  devuelven valor: un valor nuevo del enum se vuelve error de compilación.
- `abstract final class` para contenedores de constantes (`AppColors`,
  `AuthRoutes`, `Env`); `final` para locales que no cambian; constructores
  `const` donde se pueda.
- Sin `print` (lint `avoid_print`); un `debugPrint` de depuración no se
  integra.
- Formato `dart format` a 80 columnas (configurado en `.vscode/settings.json`).
- Funciones de dominio puras: mismas entradas, misma salida, sin `DateTime.now()`
  ni red adentro (si hace falta la hora, que llegue como parámetro).

## 9. Pruebas

En esta tesis las pruebas son evidencia del Objetivo 4, no un extra.

- **Lógica de dominio** → `test()` en `cupo/test/features/<feature>/`, cubriendo
  el espacio completo cuando es finito (modelo:
  `resolver_destino_test.dart`, las 30 combinaciones).
- **Pantallas** → `testWidgets` con `montarPantalla()` de
  `cupo/test/soporte/banco_de_pruebas.dart` (tema, lienzo 390×844, rutas del
  primer ingreso y `AuthScope`). Sin red: el repositorio se inyecta y la prueba
  no dispara envíos reales.
- `setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false)` en cada
  archivo de pruebas de widget.
- `group` por pantalla con su código de diseño (`'L2 — Crear cuenta'`) y
  nombres en español que describen el comportamiento
  (`'«Iniciar sesión» lleva al login'`).
- `pumpAndSettle` se cuelga con animaciones infinitas
  (`CircularProgressIndicator`): ahí usa `pump(const Duration(...))`.
- Cada bug corregido trae una prueba que lo reproduce.
- Los cálculos geográficos de `core/geo/` (Haversine, punto en polígono,
  distancia a polilínea) se escriben con pruebas primero.

## 10. Plataforma: ubicación, mapas, almacenamiento

- **geolocator**: antes de pedir la ubicación, comprobar que el servicio está
  activo y manejar `denied` y `deniedForever` con un mensaje en español que
  explique para qué se usa y cómo habilitarla. La ubicación en segundo plano es
  un flujo de dos pasos y en Android exige servicio en primer plano.
- **flutter_map** con teselas de OpenStreetMap: atribución visible y
  `userAgentPackageName` configurado (lo exige la política de uso de OSM).
- **sqflite**: base abierta una sola vez y cerrada al terminar; versiones de
  esquema con `onUpgrade`; nada de consultas pesadas en el hilo de UI sin
  `await`.
- **AndroidManifest**: solo los permisos que la función necesita, cada uno
  justificado.

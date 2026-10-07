# Reglas del repositorio Cupo

Guía de revisión de las reglas de `CLAUDE.md` y de las convenciones que el
código ya sigue aunque `CLAUDE.md` no las escriba. Cada regla dice qué mirar,
por qué importa y qué excepciones son aceptables.

## Índice

- [Códigos del script](#códigos-del-script)
- [El sistema de diseño tal como está en el código](#el-sistema-de-diseño-tal-como-está-en-el-código)
- [R1 Color](#r1-color) · [R2 Tipografía](#r2-tipografía) · [R3 fromSeed](#r3-fromseed)
- [R4 Tokens nuevos](#r4-tokens-nuevos) · [R5 Radio y elevación](#r5-radio-y-elevación)
- [R6 Espaciado](#r6-espaciado) · [R7 Estados](#r7-estados) · [R8 Light-only](#r8-light-only)
- [R9 Español es-VE](#r9-español-es-ve)
- [Arquitectura](#arquitectura)
- [Comentarios y documentación](#comentarios-y-documentación)
- [Supabase y migraciones](#supabase-y-migraciones)
- [Secretos](#secretos)
- [Material visual](#material-visual)

## Códigos del script

| Código | Qué detecta | Severidad base |
| --- | --- | --- |
| R1 | `Color(0x…)`, `Color.fromARGB/RGBO`, `Colors.*` fuera de `app_colors.dart` | Bloqueante |
| R2 | `GoogleFonts.*`, `fontFamily:`, "Caveat" fuera de `app_typography.dart` | Bloqueante |
| R2 | `TextStyle(` a mano; `AppTypography.logo/wordmark` fuera de `branding/` | Importante |
| R3 | `ColorScheme.fromSeed` | Bloqueante |
| R4 | Token de `AppColors` sin fila en la tabla de `CLAUDE.md` | Importante |
| R5 | `Radius.circular(n)` literal, `BoxShadow`, `elevation` > 0 | Importante |
| R6 | Número literal en `EdgeInsets`/`SizedBox` (no múltiplo de 4 → importante; con token equivalente → sugerencia) | Importante / Sugerencia |
| R8 | `darkTheme:` ≠ `AppTheme.dark`, `ColorScheme.dark(` / `ThemeMode.dark/system` | Bloqueante / Importante |
| R9 | Texto de UI que parece inglés, trato de usted, «contraseña», «email» | Sugerencia |
| SEG1–3 | `service_role`, JWT o URL de Supabase en el código, `.env`/`dart_define.json` en el cambio | Bloqueante |
| ARQ1 | `Supabase.instance` fuera de `data/`; `.from('…')`/`.rpc('…')` en `presentation/` | Importante |
| ARQ2 | `domain/` importa Flutter, Supabase u otro paquete de plataforma | Importante |
| ARQ3 | Widget de `shared/widgets/` sin `export` en `widgets.dart` | Sugerencia |
| ARQ4 | Código en `lib/core/theme/` (el tema vive en `lib/theme/`) | Importante |
| ARQ5 | `pushNamed('/…')` con la ruta escrita como cadena | Sugerencia |
| FLU1 | Controller/FocusNode/Timer/StreamController creado sin `dispose`/`cancel`/`close` | Importante |
| FLU2 | `.listen(` sin guardar la suscripción o sin `cancel()` | Importante |
| FLU3 | `future:`/`stream:` de un `FutureBuilder`/`StreamBuilder` creado en `build` | Importante |
| FLU4 | `MediaQuery.of(context).size` y similares | Sugerencia |
| FLU5 | `shrinkWrap: true` | Sugerencia |
| FLU6 | `IconButton` sin `tooltip`, `Image.*` sin `semanticLabel`, control táctil solo con icono | Sugerencia |
| TST1 | Archivo de `domain/` que ninguna prueba importa | Importante |
| TST2 | Pantalla (`*_screen.dart`) que ninguna prueba importa | Sugerencia |
| SQL1 | Migración existente editada | Importante |
| SQL2 | `create table` sin `enable row level security` en ninguna migración | Bloqueante |
| SQL3 | Función `security definer` sin `set search_path` | Importante |
| SQL4 | Valor de un `enum` de PostgreSQL que no aparece en el código Dart | Importante |
| DOC1 | `font-family` sin Manrope/Caveat en material visual | Importante |
| DOC2 | Hex fuera de la paleta de `CLAUDE.md` en material visual | Sugerencia |

La severidad final la decides tú con el código a la vista: puedes subirla si
hay un escenario de falla concreto o bajarla si hay una justificación válida.

## El sistema de diseño tal como está en el código

`cupo/lib/theme/` es la única fuente de color, tipografía y medidas. Se importa
siempre por el barril: `import '../../../theme/theme.dart';`.

| Clase | Qué contiene |
| --- | --- |
| `AppColors` | Los tokens de la tabla de `CLAUDE.md`, más `onPrimary` (blanco) |
| `AppTypography` | `textTheme` (escala de Material) **y** estilos con nombre: `display`, `title`, `body`, `bodyStrong`, `label`, `input`, `inputHint`, `helper`, `otpDigit`, `button`, `link`, `linkLead`, `meta`, `metaStrong`, `legal`, `wordmark`; y `manrope(...)` / `logo(...)` |
| `AppSpacing` | `xxs` 4 · `xs` 8 · `sm` 12 · `md` 16 · `lg` 20 · `xl` 24 · `xxl` 32 · `xxxl` 48 · `screenH` 24 · `screenBottom` 24 |
| `AppRadius` | `sm` 12 (campos) · `md` 14 (botones, retroceso, OTP, avisos) · `brand` 24 (mosaico del logo), con sus `*All` |
| `AppSizes` | Alturas fijas: `button` 60, `field` 56, `iconButton` 44, `otpBox` 68, `logoTile` 78, `border` 1.5, `borderFocused` 2 |
| `AppTheme` | `radius` 12, `borderRadius`, `colorScheme` explícito, `light` |

`CLAUDE.md` va un paso atrás del código en dos puntos; no los marques como
error:

- La regla 2 nombra `textTheme` y `AppTypography.manrope(...)`, pero los
  **estilos con nombre** de `AppTypography` son la forma preferida en las
  pantallas del primer ingreso. Un `AppTypography.manrope(...)` suelto fuera
  del tema es válido, pero si se repite, propón un estilo con nombre.
- La regla 5 nombra `AppTheme.radius` (12). `AppRadius.md` (14) y
  `AppRadius.brand` (24) salieron del diseño y son igual de válidos.

## R1 Color

**Regla:** ningún literal de color fuera de `cupo/lib/theme/app_colors.dart`.
Se usa `AppColors.*` o `Theme.of(context).colorScheme.*`.

**Por qué:** la paleta está definida en OkLCH y aprobada por marca; un hex
suelto rompe la familia de tono y no se puede cambiar desde un solo lugar.

```dart
// ✗
color: Color(0xFF007C8A),
color: Colors.grey.shade200,
// ✓
color: AppColors.primary,
color: AppColors.backgroundAlt,
color: Theme.of(context).colorScheme.outline,
```

**Aceptado:**

- `Colors.transparent` (no introduce un tono; `app_theme.dart` lo usa).
- Variar la opacidad de un token: `foreground.withValues(alpha: 0.10)`
  (patrón de `CupoButtonShell`). `withOpacity` está deprecado.
- `google_glyph.dart` pinta la «G» con los colores oficiales de Google: es
  previo a esta revisión. Si un cambio lo toca, propón moverlos a `AppColors`
  como `googleBlue`, `googleRed`… documentados en `CLAUDE.md`, o marcarlos con
  `// cupo-ignore: R1 colores oficiales de Google`.

En pruebas, compara contra `AppColors.*`, no contra hex.

## R2 Tipografía

**Regla:** Manrope (400–800) para toda la UI; Caveat 700 solo para el
logotipo «Cupo». Nada de `fontFamily`, `GoogleFonts.*` ni `TextStyle(...)`
fuera de `app_typography.dart`. Nunca una tercera familia.

```dart
// ✗
Text('Hola', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))
Text('Hola', style: GoogleFonts.manrope(fontSize: 16))
// ✓
Text('Hola', style: AppTypography.bodyStrong)
Text('Hola', style: Theme.of(context).textTheme.titleMedium)
Text('Hola', style: AppTypography.body.copyWith(color: AppColors.ink))
```

Revisa también a mano:

- `copyWith(fontFamily: …)` o pesos fuera de `w400`–`w800`.
- Caveat solo pinta la palabra «Cupo», y se usa a través de `CupoWordmark` o
  `CupoLockup`. Un título o un número en Caveat es un error aunque pase el
  script.
- Las pruebas de widget ponen `GoogleFonts.config.allowRuntimeFetching = false`
  en `setUpAll`, o intentan descargar la fuente.

## R3 fromSeed

`ColorScheme.fromSeed` genera tonos que no son de la marca. El esquema es
explícito en `AppTheme.colorScheme`; si un componente necesita un rol de color
que falta ahí, se agrega en el esquema con un token existente.

## R4 Tokens nuevos

Un tono nuevo se agrega **primero** como token en `AppColors` con su OkLCH en
el comentario de documentación, **y** se documenta en la tabla de `CLAUDE.md`;
recién entonces se usa. Las dos partes van en el mismo cambio.

```dart
/// oklch(0.95 0.03 250) — fondo de avisos informativos de sistema.
static const Color infoSoft = Color(0xFFE5EEF9);
```

Lo mismo para `AppSpacing`, `AppRadius` y `AppSizes`: el comentario dice de
dónde sale la medida («medido sobre el diseño», «separación entre…»).

Hueco conocido: `AppColors.onPrimary` no tiene fila en `CLAUDE.md`.

## R5 Radio y elevación

- Radios: `AppTheme.borderRadius` (12) o `AppRadius.smAll/mdAll/brandAll`.
  Nunca `BorderRadius.circular(8)`.
- Elevación por defecto 0. La jerarquía se expresa con borde (`AppColors.border`,
  grosor `AppSizes.border`) y fondo alterno (`AppColors.backgroundAlt`), no con
  sombras. `BoxShadow`, `Card(elevation: 2)`, `Material(elevation: …)` o
  `PhysicalModel` son hallazgos.
- `surfaceTintColor` ya viene transparente desde el tema; no hace falta
  repetirlo, y no debe ponerse en otro color.

## R6 Espaciado

- Todo en múltiplos de 4, con los tokens de `AppSpacing`.
- Padding lateral de pantalla 16–24: las pantallas nuevas usan `CupoScreen`,
  que ya aplica `AppSpacing.screenH` (24) y el área segura.
- Separación ≠ tamaño. La altura de un componente va en `AppSizes`, no en
  `AppSpacing`. Grosores de trazo (`strokeWidth: 2.4`, `cursorWidth: 1.6`,
  `AppSizes.border` 1.5) no son espaciado.
- Si un valor múltiplo de 4 aparece más de una vez sin token, propón el token.
- Dentro de `lib/theme/` los literales son la fuente y no se marcan.

## R7 Estados

| Estado | Primer plano | Fondo | Widget existente |
| --- | --- | --- | --- |
| Confirmado | `success` | `successSoft` | — |
| Pendiente / próximo a vencer | `warning` | `warningSoft` | — |
| Error / cancelado | `danger` | `dangerSoft` | `CupoErrorBanner` |
| Informativo | `primaryDeep` / `primary` | `primarySoft` | `CupoInfoBanner` |

Revisa a mano:

- Que el par sea el correcto (un pendiente en verde es un error de
  significado, no de estilo).
- Que el estado no se comunique **solo** con color: lleva texto
  («Confirmado») o icono.
- Contraste: `success` (≈3.4:1) y `warning` (≈3:1) sobre fondo claro no
  alcanzan 4.5:1. Úsalos para iconos, bordes, puntos o texto grande/negrita;
  el texto pequeño va en `ink` (como hace `CupoErrorBanner`).
- Antes de crear un banner o una etiqueta de estado nueva, mira si
  `CupoErrorBanner`/`CupoInfoBanner` sirven o se pueden generalizar.

## R8 Light-only

No hay tema oscuro. Si se agrega, va como `AppTheme.dark` con tokens propios en
`lib/theme/`, nunca invirtiendo o calculando colores al vuelo
(`Brightness.dark ? … : …`, `computeLuminance()` para elegir texto, etc.).

## R9 Español es-VE

Todo texto visible va en español de Venezuela:

- **Tuteo**: «Escribe tu correo», «¿Ya tienes cuenta?». Nada de usted
  («Ingrese su…») ni voseo.
- **Vocabulario del producto**: *clave* (no contraseña), *correo* (no email),
  *cédula*, *teléfono (el de WhatsApp)*, *conductor*, *estudiante*, *puesto*,
  *cupo*, *ruta*, *turno*, *unidad*, *carro* (no coche/auto).
- **Signos**: apertura `¿` y `¡`; comillas latinas «» en textos y comentarios.
- **Mensajes de error**: dicen qué hacer, en tono cercano («Escribe un correo
  válido.», «No hay conexión. Revisa tus datos o el wifi.»). Los errores del
  backend se traducen en el repositorio (`_traducir`); mostrar `e.toString()`
  de una excepción cruda en pantalla es un hallazgo.
- Los identificadores de dominio están en español (`repositorio`, `usuario`,
  `estado`, `enviarARevision`); las clases de pantalla terminan en `Screen`.
  Sigue lo que hagan los archivos vecinos.

## Arquitectura

Organización por feature: `cupo/lib/features/<feature>/{data,domain,presentation}`,
más `shared/widgets/`, `theme/` y `core/config/`.

- **data/** — Un repositorio por feature, único lugar que habla con Supabase.
  Recibe el `SupabaseClient` opcional por constructor y lo resuelve tarde
  (`_inyectado ?? Supabase.instance.client`) para que las pruebas no necesiten
  red. Traduce `AuthException`/`PostgrestException` a una excepción propia con
  mensaje en español (`AuthFallo`).
- **domain/** — Dart puro: modelos, enums y funciones sin Flutter ni red, para
  probarlos con `test()`. Los enums espejo de PostgreSQL llevan un campo
  `valor` con el texto exacto de la base y un `desde(String)` que revienta ante
  valores desconocidos; **no** se usa `.name`, porque un renombre en Dart
  rompería la consulta en silencio. `fromMap` vive aquí.
- **presentation/** — Pantallas y widgets de la feature. Llegan al repositorio
  y al usuario con `AuthScope.de(context)` (un `InheritedWidget`). Agregar un
  paquete de manejo de estado (provider, riverpod, bloc) es una decisión de
  arquitectura: debe estar escrita en `docs/producto/` antes de entrar.
- **Navegación** — Las rutas con nombre son solo las del primer ingreso
  (`AuthRoutes`). Después del login, la pantalla la decide
  `resolverDestino()` + `destinoPantalla()`; empujar por nombre una pantalla
  posterior al login crea una segunda fuente de verdad. Los `switch` sobre
  enums van sin `default`, para que el analizador obligue a cubrir un valor
  nuevo.
- **Widgets compartidos** — En `shared/widgets/<categoría>/cupo_*.dart`
  (branding, buttons, feedback, inputs, layout, text), clase con prefijo
  `Cupo`, un widget público por archivo, exportado en `widgets.dart`. Las
  pantallas importan el barril. Antes de crear uno, revisa si ya existe:
  `CupoScreen`, `CupoPrimaryButton` (uno solo por vista), `CupoSecondaryButton`,
  `CupoGoogleButton`, `CupoBackButton`, `CupoField` + `CupoTextInput` /
  `CupoPasswordInput` / `CupoOtpInput`, `CupoChoiceTile`, `CupoErrorBanner`,
  `CupoInfoBanner`, `CupoDividerLabel`, `CupoInlineLinkText`, `CupoLink`.
- **Imports** — Relativos dentro de `lib/`; `package:cupo/…` en `test/`.
- **Dependencias nuevas** — Justificadas con un comentario en `pubspec.yaml`
  (como el de `supabase_flutter`), paquete mantenido, sin duplicar algo que ya
  hace otra dependencia. `pubspec.lock` se versiona (es una app).

## Comentarios y documentación

- El código documenta el **porqué** con `///` en español y remite al modelo
  («apartado 6 del modelo de datos»). Clases y funciones públicas nuevas
  llevan su comentario con una densidad parecida a la de sus vecinos. No se
  narra lo que el código ya dice.
- Si el cambio altera el modelo (tablas, estados, enrutamiento), actualiza
  `docs/producto/modelo-de-datos.md` en el mismo cambio.
- `docs/tesis/` es generado: no se edita a mano.
- Nada de código comentado ni `TODO` sin contexto (un `TODO` que remite a
  `TODO.md` está bien).

## Supabase y migraciones

- Cada cambio de esquema es un archivo nuevo
  `supabase/migrations/AAAAMMDDhhmmss_descripcion.sql`. Editar una migración
  ya aplicada no la vuelve a ejecutar.
- Toda tabla nueva: `alter table … enable row level security` y sus políticas.
  Sin RLS, la anon key —que viaja dentro de la app y cualquiera puede leer—
  abre la tabla a todo el mundo.
- Si el usuario solo puede escribir algunas columnas, se usan privilegios por
  columna (patrón de la migración 06). Las transiciones de estado van por
  funciones `security definer` con `set search_path = public` y la validación
  adentro (migración 07), invocadas con `.rpc()`.
- Cada `create type … as enum` tiene su enum espejo en `domain/` con los
  mismos valores, y al revés.
- Si la app escucha la tabla con `.stream()`, la tabla debe estar en la
  publicación de Realtime (migración 09).
- En Dart: filtro explícito `.eq('id', id)` aunque el RLS ya limite;
  `maybeSingle()` cuando la fila puede no existir; excepciones traducidas.

## Secretos

- Las credenciales entran por `--dart-define-from-file=dart_define.json`
  (`Env`). `dart_define.json` y `.env` están en `.gitignore`; solo se versionan
  sus `.example`.
- La anon key es pública por diseño; la `service_role` key **nunca** entra a la
  app ni al repositorio.

## Material visual

Mockups, diagramas, HTML, SVG, presentaciones y capturas usan la misma
identidad: Manrope para todo el texto, Caveat 700 solo para el logotipo «Cupo»,
verde lago como acento y los neutros de `CLAUDE.md` para fondos y texto. Los
colores de Google solo son aceptables dentro del botón «Continuar con Google».
Las familias de respaldo (`sans-serif`, `Helvetica`) están bien detrás de
Manrope.

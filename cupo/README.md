# Cupo — aplicación móvil

Aplicación Flutter para Android del sistema de gestión de cupos de transporte
estudiantil. Es el artefacto de software de la tesis: cubre los objetivos
específicos 3, 4 y 5 (diseño lógico y físico, verificación y manual de usuario).

- Package: `com.cupo.app`
- Plataforma: Android únicamente (`minSdk 26`, RNF-01)
- Backend: **Supabase** (Auth, Postgres, Realtime). El proyecto no usa Firebase
- Documentación viva del producto: [`../docs/producto/`](../docs/producto/)
- Plan de trabajo: [`../TODO.md`](../TODO.md)

---

## Instalación

Son cuatro pasos. El proyecto ya existe en el repositorio: no hay que crearlo
ni configurar Android a mano — eso ya está hecho y versionado. Lo que sigue
supone un Supabase ya montado; si vas a crear el tuyo, pasa antes por
[Montar Supabase desde cero](#montar-supabase-desde-cero).

**1. Requisitos** — tres cosas, nada más:

| Qué | Versión | Cómo comprobarlo |
|---|---|---|
| Flutter (canal stable) | 3.47+ · Dart 3.13+ | `flutter --version` |
| JDK | 17 | `java -version` |
| Android SDK (`cmdline-tools`) | platform 36, build-tools 35 | `flutter doctor` |

Si no tienes nada de eso instalado, ahí está el trabajo real —no en los otros
tres pasos—: una tarde, tres descargas y un `PATH` que hay que armar a mano.
Está todo en el [Apéndice D](#apéndice-d--instalar-los-requisitos-en-windows).

No hace falta Android Studio. Si el SDK ya existe pero está en otra ruta:
`flutter config --android-sdk /ruta/al/android-sdk`.

`flutter doctor` va a marcar *Android Studio* ausente, *Visual Studio* ausente
y *Android license status unknown*. Los tres son esperados y no bloquean nada.

**2. Dependencias:**

```bash
cd cupo
flutter pub get
```

**3. Credenciales de Supabase** — en **Project Settings → API** del panel están
`Project URL` y la `anon public` key:

```bash
cp dart_define.example.json dart_define.json   # y pega ahí los dos valores
```

`dart_define.json` está en `.gitignore`. La `anon key` es pública por diseño —va
dentro de la app— y lo que protege los datos es el RLS, no ella. La que **nunca**
entra al repositorio ni a la app es la `service_role`, que salta el RLS entero.

**4. Correr**, con el teléfono conectado y la depuración USB activada:

```bash
flutter run --dart-define-from-file=dart_define.json
```

Si arranca y llega a la pantalla de login, la instalación está lista.

### Comprobar que todo está sano

```bash
flutter analyze    # sin issues
flutter test       # en verde
```

El detalle de cómo preparar el teléfono, qué teclas acepta `flutter run` y qué
hacer si `adb` no ve el dispositivo está en el [README raíz](../README.md).

### Opcional

Lo de abajo no hace falta para que la app corra. Está separado a propósito:

- **Extensiones de VS Code y herramientas de línea de comandos** →
  [Apéndice B](#apéndice-b--herramientas-y-extensiones). De todo eso, solo dos
  extensiones son obligatorias: Dart y Flutter.
- **Supabase desde Claude Code (MCP)** → [Apéndice C](#apéndice-c--supabase-desde-claude-code-mcp).
- **Qué estudiar antes de tirar código y recursos** →
  [`APRENDER.md`](APRENDER.md).

---

## Montar Supabase desde cero

Solo si no tienes un proyecto Supabase al que apuntar. Si ya te pasaron la
URL y la `anon key`, salta esto: con el paso 3 de la instalación basta.

### Crear el proyecto

En [supabase.com](https://supabase.com) → **New project**. Región: la más
cercana (`East US`). Anota la contraseña de la base: no se vuelve a mostrar.

Conviene crear **dos proyectos**: uno de desarrollo y otro para la
demostración final. No se quiere estar borrando datos de prueba la noche
antes de la defensa.

### Aplicar el esquema

Las migraciones están en [`supabase/migrations/`](../supabase/migrations/),
numeradas y en orden. Cada archivo corresponde a un apartado del modelo de
datos.

Con la CLI:

```bash
npm install -g supabase
supabase link --project-ref <ref-del-proyecto>
supabase db push
```

O a mano: abrir el **SQL Editor** del panel y pegar los ocho archivos **en
orden**, del `0001` al `0009`. El orden importa: las tablas necesitan los
tipos, las políticas necesitan las tablas.

### Correo

En **Authentication → Providers**:

- **Email**: para desarrollar, apagar *Confirm email*. Si queda encendido, el
  registro no abre sesión hasta que la persona abra el correo, y la app lo
  dice pero no puede seguir.

En **Authentication → URL Configuration**, agregar como *Redirect URL*:

```
io.supabase.cupo://login-callback/
```

Ese esquema ya está declarado en `AndroidManifest.xml`.

### Crear el primer administrador

El trigger `crear_usuario()` **nunca** concede el rol de administrador: es una
lista blanca de `estudiante` y `conductor`, y es la defensa contra que
cualquiera se registre como admin. El primero se marca a mano, una sola vez,
desde el SQL Editor:

```sql
update public.usuarios
   set rol = 'administrador', estado = 'aprobada', onboarding_completo = true
 where email = 'tu-correo@ejemplo.com';
```

### Probar el enrutamiento sin esperar aprobaciones

La tabla del apartado 6 se recorre entera cambiando una columna:

```sql
update public.usuarios set estado = 'aprobada'  where email = '...';
update public.usuarios set estado = 'rechazada',
       motivo_rechazo = 'La foto de la licencia está borrosa.' where email = '...';
update public.usuarios set estado = 'suspendida' where email = '...';
```

Con la app abierta, la pantalla **cambia sola**: está suscrita a su propia fila
por Realtime.

---

# Apéndices

Nada de lo que sigue hace falta para instalar ni para correr la app.

## Apéndice A — Cómo se construyó el proyecto

Queda documentado porque la tesis debe poder explicar cada decisión de
configuración ante el jurado, no porque haya que repetirlo: todo esto ya
está hecho y versionado.

### Generar el proyecto Flutter

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

### Configurar Android

`android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 36   // lo exigen sqflite_android y package_info_plus
    defaultConfig {
        applicationId = "com.cupo.app"
        minSdk = 26        // Android 8.0 — RNF-01
        targetSdk = 35
    }
}
```

El `applicationId` es la identidad definitiva de la app y **no se puede cambiar
después de publicar**, así que hay que fijarlo aquí desde el principio.

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

### Estructura de carpetas

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
    services/        supabase, notificaciones, ubicación
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

Los cálculos de `core/geo/` son Dart puro, sin dependencias de Flutter ni del
backend. Eso permite cubrirlos con pruebas unitarias, y esas pruebas son
evidencia directa para el Objetivo 4.

### Dependencias

```bash
flutter pub add supabase_flutter
flutter pub add geolocator flutter_map latlong2 sqflite intl
flutter pub add --dev flutter_lints test
```

Quedan fuera por ahora `flutter_background_geolocation` y
`geoflutterfire_plus`: se agregan cuando lleguen los spikes que los necesitan,
no antes.

### Higiene inicial

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
dart_define.json
*.jks
key.properties
.env
```

## Apéndice B — Herramientas y extensiones

### Extensiones de VS Code — imprescindibles

Sin estas cuatro no se trabaja cómodo. Las dos primeras son obligatorias.

| Extensión | ID | Para qué |
|---|---|---|
| Dart | `Dart-Code.dart-code` | Analizador, autocompletado, formateo, depurador. **Obligatoria.** |
| Flutter | `Dart-Code.flutter` | Hot reload, selector de dispositivo, DevTools, `flutter create` desde la paleta. **Obligatoria.** |
| Error Lens | `usernamehw.errorlens` | Muestra el error en la misma línea, sin ir al panel de problemas. Con null safety, ahorra horas. |
| Awesome Flutter Snippets | `Nash.awesome-flutter-snippets` | `statelessW`, `streamBldr` y demás. Evita escribir el mismo boilerplate cincuenta veces. |

### Extensiones de VS Code — recomendadas

| Extensión | ID | Para qué |
|---|---|---|
| Flutter Riverpod Snippets | `robert-brunhage.flutter-riverpod-snippets` | Solo si se elige Riverpod para el manejo de estado. |
| Pubspec Assist | `jeroen-meijer.pubspec-assist` | Agrega dependencias con la versión correcta sin abrir pub.dev. |
| Dart Data Class Generator | `hzgood.dart-data-class-generator` | Genera `fromJson`/`toJson`/`copyWith` de los modelos. Mucho tiempo ahorrado en la Fase 3. |
| PostgreSQL | `ms-ossdata.vscode-pgsql` | Consultar las tablas de Supabase sin salir del editor. |
| Bruno | `bruno-api-client.bruno` | Cliente de API embebido en VS Code (ver abajo). |
| Better Comments | `aaron-bond.better-comments` | Resalta `TODO:` y `FIXME:`, útil con el plan de fases. |
| GitLens | `eamodio.gitlens` | Historial y culpa por línea. |
| Markdown All in One | `yzhang.markdown-all-in-one` | Para la documentación de `docs/`, que es la mitad del trabajo de tesis. |

Instalación en bloque:

```bash
code --install-extension Dart-Code.dart-code \
     --install-extension Dart-Code.flutter \
     --install-extension usernamehw.errorlens \
     --install-extension Nash.awesome-flutter-snippets \
     --install-extension jeroen-meijer.pubspec-assist \
     --install-extension hzgood.dart-data-class-generator \
     --install-extension eamodio.gitlens
```

### Configuración recomendada de VS Code

En `.vscode/settings.json` del proyecto:

```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "dart.previewFlutterUiGuides": true,
  "dart.lineLength": 80,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.codeActionsOnSave": { "source.fixAll": "explicit" }
  }
}
```

`formatOnSave` no es cosmético: elimina por completo las discusiones de estilo y
los diffs sucios en git.

### Bruno — pruebas de endpoints

[Bruno](https://www.usebruno.com) es un cliente de API tipo Postman, pero
**guarda las colecciones como archivos de texto dentro del repositorio**. Eso
importa aquí por dos razones: las peticiones se versionan en git junto al código,
y no hace falta cuenta ni sincronización en la nube.

```bash
# Windows
winget install Bruno.Bruno
# macOS
brew install bruno
```

Convención para este proyecto: colección en `api/` (fuera de `lib/`), con
entornos separados para desarrollo y demostración.

```
api/
  environments/
    dev.bru          # apunta al proyecto Supabase de desarrollo
    demo.bru         # apunta al de la defensa
  auth/
    signup.bru
    signin.bru
  rest/
    listar-turnos.bru
```

**Importante:** las claves de API y los tokens van en el archivo de entorno, y
los entornos **no se comitean**. Agregar a `.gitignore`:

```
api/environments/*.bru
!api/environments/*.example.bru
```

Para qué sirve concretamente en este proyecto:

- Probar la **API de Auth de Supabase** (registro y login) sin compilar la app.
- Consultar la **API REST de PostgREST** para verificar que una fila quedó como
  se esperaba, o para poblar datos de prueba.
- Comprobar que el **RLS** bloquea lo que debe: la misma consulta con la `anon
  key` y con una sesión distinta.
- Probar **OSRM** o el servicio de rutas que se elija en la Fase 0, y ver la
  respuesta cruda antes de escribir el parser en Dart.

### Herramientas de línea de comandos

| Herramienta | Instalación | Para qué |
|---|---|---|
| **adb** | viene con `platform-tools` | `adb devices`, `adb logcat`, `adb shell dumpsys location`. Indispensable en el Spike 1. |
| **scrcpy** | `winget install Genymobile.scrcpy` | Espeja la pantalla del teléfono en la PC. Vale oro para grabar la demostración de la defensa. |
| **Supabase CLI** | `npm i -g supabase` | `supabase db push` para aplicar las migraciones, `supabase start` para el stack local. |
| **Flutter DevTools** | incluido en Flutter | Inspector de widgets, profiler, vista de red. Se abre con `flutter run` en curso. |

### Stack local de Supabase

```bash
supabase start      # Postgres, Auth y Realtime en Docker
supabase db push    # aplica las migraciones de supabase/migrations/
```

Vale la pena montarlo antes de la Iteración 1. Permite probar las políticas de
RLS y las consultas sin conexión y sin ensuciar el proyecto de datos reales —
que es exactamente lo que hace falta cuando se está depurando el mismo flujo
veinte veces seguidas. Requiere Docker.

### Dispositivo de pruebas

Un **teléfono físico**, no el emulador. El emulador de Android simula mal el GPS
y no reproduce el comportamiento de la batería ni las restricciones del
fabricante, que son justamente el riesgo del Spike 1. En el teléfono hay que
activar Opciones de desarrollador y Depuración por USB.

---

## Apéndice C — Supabase desde Claude Code (MCP)

El repositorio trae [`.mcp.json`](../.mcp.json) en la raíz: conecta Claude Code
con la cuenta de Supabase para crear el proyecto, aplicar migraciones,
consultar tablas y leer logs sin salir del editor.

**El archivo no contiene la credencial.** Lleva `${SUPABASE_ACCESS_TOKEN}`, que
se expande desde una variable de entorno, así que se puede versionar sin
riesgo. El token se guarda una sola vez, en la máquina:

1. Sacarlo en [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)
   → **Generate new token**. Se muestra una sola vez.
2. Anotarlo en `.env` en la raíz del repositorio —ignorado por git— con el
   nombre exacto de la variable, que es el que busca `.mcp.json`:

   ```
   SUPABASE_ACCESS_TOKEN=sbp_el-token-que-copiaste
   ```

   Hay una plantilla en [`.env.example`](../.env.example).

3. Pasarlo al entorno del usuario. **Claude Code no lee archivos `.env`**: la
   expansión `${SUPABASE_ACCESS_TOKEN}` de `.mcp.json` sale del entorno del
   proceso, así que el `.env` por sí solo no alcanza.

   ```powershell
   $v = ((Get-Content .env | Where-Object { $_ -match '^SUPABASE_ACCESS_TOKEN=' }) -split '=',2)[1].Trim()
   [Environment]::SetEnvironmentVariable('SUPABASE_ACCESS_TOKEN', $v, 'User')
   ```

4. **Cerrar y reabrir VS Code.** La variable solo llega a procesos nuevos.
5. Claude Code pregunta si se confía en el servidor MCP del proyecto la
   primera vez. Con `/mcp` se ve el estado de la conexión.

El token vale por **toda la cuenta**, no por un proyecto. Conviene borrarlo del
panel cuando se termine la tesis.

### Alcance concedido

| Grupo | Para qué |
|---|---|
| `account` | listar y crear proyectos |
| `database` | aplicar migraciones, consultar tablas, ver el esquema |
| `development` | leer la URL y la `anon key` (las de `dart_define.json`) |
| `debugging` | logs y avisos del asesor de seguridad |
| `docs` | buscar en la documentación de Supabase |

Quedan fuera `branching`, `functions` y `storage`: no hacen falta todavía y
cada grupo apagado es superficie que no se expone.

**Tiene permiso de escritura**, a propósito: es lo que permite aplicar las
nueve migraciones desde aquí. Eso implica que un texto malicioso guardado en
la base podría, en teoría, inducir una escritura no pedida. En una base de
tesis sin datos de terceros el riesgo es asumible; el día que haya usuarios
reales, agregar `--read-only` a los argumentos y aplicar los cambios por la
CLI.

## Apéndice D — Instalar los requisitos en Windows

Si ya tienes Flutter, el JDK 17 y el Android SDK funcionando, sáltate esto.

Lo que sigue es lo que se hizo en esta máquina, en este orden. Toma una tarde la
primera vez, casi toda en descargas. Nada de esto es difícil: es tedioso, y el
único punto donde se tranca la gente es el `PATH`.

### 1. JDK 17

```powershell
winget install EclipseAdoptium.Temurin.17.JDK
```

Tiene que ser **17**. Con el 21 o el 25 el plugin de Gradle de Android falla, y
el error que tira no menciona la versión de Java por ningún lado.

### 2. Flutter

**No está en winget** —no hay paquete oficial— así que es descarga manual:

1. Bajar el zip del canal stable de
   [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2. Descomprimir en **`C:\src\flutter`**. No en `Program Files`: la ruta con
   espacios rompe algunos scripts de build, y nada te avisa.

### 3. Android SDK, sin Android Studio

1. Bajar **Command line tools only** de
   [developer.android.com/studio](https://developer.android.com/studio#command-line-tools-only)
   — está al final de la página, no en el botón grande de arriba.
2. Descomprimir de forma que quede exactamente esta ruta. El `latest` de en
   medio no es opcional: el CLI se busca a sí mismo ahí.

   ```
   %LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\
   ```

3. Instalar los paquetes. **Ojo con la sintaxis**: Google deprecó
   `sdkmanager "paquete;version"` y lo delegó en un CLI `android` que usa `/`
   en vez de `;`. Casi todos los tutoriales que vas a encontrar enseñan la
   forma vieja, que ya no funciona.

   ```powershell
   cd $env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin
   .\android sdk install platforms/android-36
   .\android sdk install build-tools/35.0.0
   .\android sdk install platform-tools
   .\android sdk install ndk/28.2.13676358
   ```

   El NDK hay que ponerlo a mano por lo mismo: el plugin de Gradle intenta
   auto-instalarlo por la vía vieja y falla.

### 4. Variables de entorno

Aquí es donde se tranca todo el mundo. A nivel de **usuario**:

```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', "$env:ProgramFiles\Eclipse Adoptium\jdk-17.0.20.101-hotspot", 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', "$env:LOCALAPPDATA\Android\Sdk", 'User')

$ruta = [Environment]::GetEnvironmentVariable('PATH', 'User')
$agregar = @(
  'C:\src\flutter\bin'
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
  "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin"
  "$env:LOCALAPPDATA\Pub\Cache\bin"
) -join ';'
[Environment]::SetEnvironmentVariable('PATH', "$ruta;$agregar", 'User')
```

Ajusta la ruta de `JAVA_HOME` a la versión que te haya instalado winget;
`Get-ChildItem "$env:ProgramFiles\Eclipse Adoptium"` te la dice.

**Cierra la terminal y abre una nueva.** Las ya abiertas conservan el `PATH`
viejo, y eso es la causa del 90% de los "pero si lo acabo de instalar".

### 5. Comprobar

```powershell
flutter doctor -v
```

Los tres avisos esperados —Android Studio, Visual Studio y *Android license
status unknown*— están explicados en el [paso 1 de la instalación](#instalación).
Cualquier otra cosa en rojo sí hay que resolverla antes de seguir.

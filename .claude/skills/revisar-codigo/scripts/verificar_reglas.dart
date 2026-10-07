// Verificador automático de las reglas de CLAUDE.md para el repositorio Cupo.
//
// Uso, desde cualquier carpeta del repositorio:
//
//   dart .claude/skills/revisar-codigo/scripts/verificar_reglas.dart [opciones] [rutas...]
//
//   (sin nada)      cambios sin commitear respecto de HEAD, más archivos nuevos
//   --base <ref>    cambios desde que la rama se separó de <ref> (incluye lo
//                   que no está commiteado)
//   --todo          cupo/lib, cupo/test, supabase/migrations y docs completos
//   rutas...        esos archivos o carpetas completos
//
// En los dos primeros modos solo se informa lo que cae en líneas cambiadas: la
// revisión habla del cambio, no de la deuda que ya estaba.
//
// Un hallazgo justificado se silencia con un comentario en la misma línea o en
// la anterior, nombrando la regla y el motivo:
//
//   // cupo-ignore: R1 colores oficiales del logo de Google
//
// Sale con código 1 si hay al menos un hallazgo bloqueante.
//
// Solo usa dart:io para poder correr sin pubspec ni dependencias.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Modelo
// ---------------------------------------------------------------------------

enum Severidad {
  bloqueante('BLOQUEANTE'),
  importante('IMPORTANTE'),
  sugerencia('SUGERENCIA');

  const Severidad(this.etiqueta);
  final String etiqueta;
}

class Hallazgo {
  Hallazgo(this.regla, this.severidad, this.archivo, this.linea, this.mensaje);

  final String regla;
  final Severidad severidad;

  /// Relativo a la raíz del repositorio, con `/`.
  final String archivo;

  /// 0 cuando el hallazgo es sobre el archivo entero.
  final int linea;
  final String mensaje;
}

/// Un archivo de texto ya leído, con versiones "limpias" para buscar patrones
/// sin tropezar con comentarios ni con el contenido de las cadenas.
class Fuente {
  Fuente(this.ruta, this.original, {required bool esDart}) {
    _inicios = [0];
    for (var i = 0; i < original.length; i++) {
      if (original.codeUnitAt(i) == 0x0A) _inicios.add(i + 1);
    }
    if (esDart) {
      _lexDart();
    } else {
      codigo = original;
      estructura = original;
    }
  }

  final String ruta;
  final String original;

  /// Comentarios en blanco; cadenas intactas. Saltos de línea conservados.
  late final String codigo;

  /// Comentarios y contenido de cadenas en blanco; comillas conservadas.
  late final String estructura;

  /// Literales de cadena (sin las comillas) con su posición.
  final List<({int inicio, String texto})> literales = [];

  late final List<int> _inicios;
  late final List<String> _lineas = original.split('\n');

  int lineaDe(int offset) {
    var lo = 0, hi = _inicios.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_inicios[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  String lineaOriginal(int n) =>
      n >= 1 && n <= _lineas.length ? _lineas[n - 1] : '';

  /// Texto entre el paréntesis que abre en [abre] y su pareja, sobre
  /// [estructura]. Devuelve `null` si no cierra.
  ({int inicio, String texto})? argumentos(int abre) {
    var nivel = 0;
    for (var i = abre; i < estructura.length; i++) {
      final c = estructura[i];
      if (c == '(') nivel++;
      if (c == ')') {
        nivel--;
        if (nivel == 0) {
          return (inicio: abre + 1, texto: estructura.substring(abre + 1, i));
        }
      }
    }
    return null;
  }

  // --- Lexer mínimo de Dart -------------------------------------------------

  late List<int> _cod;
  late List<int> _est;

  void _blanco(List<int> buf, int desde, int hasta) {
    for (var i = desde; i < hasta && i < buf.length; i++) {
      if (buf[i] != 0x0A && buf[i] != 0x0D) buf[i] = 0x20;
    }
  }

  void _lexDart() {
    _cod = original.codeUnits.toList();
    _est = original.codeUnits.toList();
    _codigoDart(0, enInterpolacion: false);
    codigo = String.fromCharCodes(_cod);
    estructura = String.fromCharCodes(_est);
  }

  static bool _esIdent(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

  int _codigoDart(int i, {required bool enInterpolacion}) {
    final s = original;
    final n = s.length;
    var llaves = 0;
    while (i < n) {
      final c = s[i];
      final sig = i + 1 < n ? s[i + 1] : '';
      if (c == '/' && sig == '/') {
        final fin = s.indexOf('\n', i);
        final f = fin == -1 ? n : fin;
        _blanco(_cod, i, f);
        _blanco(_est, i, f);
        i = f;
        continue;
      }
      if (c == '/' && sig == '*') {
        var prof = 1;
        var j = i + 2;
        while (j < n && prof > 0) {
          if (s.startsWith('/*', j)) {
            prof++;
            j += 2;
          } else if (s.startsWith('*/', j)) {
            prof--;
            j += 2;
          } else {
            j++;
          }
        }
        _blanco(_cod, i, j);
        _blanco(_est, i, j);
        i = j;
        continue;
      }
      if (c == 'r' &&
          (sig == "'" || sig == '"') &&
          (i == 0 || !_esIdent(s[i - 1]))) {
        i = _cadena(i + 1, crudo: true);
        continue;
      }
      if (c == "'" || c == '"') {
        i = _cadena(i, crudo: false);
        continue;
      }
      if (enInterpolacion) {
        if (c == '{') llaves++;
        if (c == '}') {
          if (llaves == 0) return i + 1;
          llaves--;
        }
      }
      i++;
    }
    return i;
  }

  int _cadena(int i, {required bool crudo}) {
    final s = original;
    final n = s.length;
    final q = s[i];
    final triple = s.startsWith(q * 3, i);
    final cierre = triple ? q * 3 : q;
    var j = i + cierre.length;
    final inicioTexto = j;
    final texto = StringBuffer();
    while (j < n) {
      if (s.startsWith(cierre, j)) {
        literales.add((inicio: inicioTexto, texto: texto.toString()));
        return j + cierre.length;
      }
      final c = s[j];
      if (!triple && c == '\n') break; // cadena sin cerrar: no arrastrar
      if (!crudo && c == r'\') {
        texto.write(s.substring(j, math.min(j + 2, n)));
        _blanco(_est, j, j + 2);
        j += 2;
        continue;
      }
      if (!crudo && c == r'$' && j + 1 < n && s[j + 1] == '{') {
        texto.write(' ');
        _blanco(_est, j, j + 2);
        final fin = _codigoDart(j + 2, enInterpolacion: true);
        _blanco(_est, fin - 1, fin);
        j = fin;
        continue;
      }
      texto.write(c);
      _blanco(_est, j, j + 1);
      j++;
    }
    literales.add((inicio: inicioTexto, texto: texto.toString()));
    return j;
  }
}

// ---------------------------------------------------------------------------
// Contexto del repositorio
// ---------------------------------------------------------------------------

late final String raiz;
late final String claudeMd;
late final Map<double, String> tokensEspaciado;
late final Set<String> hexDeMarca;
late final List<Fuente> pruebas;
late final String exportsWidgets;
late final String todasLasMigraciones;
late final String codigoLib;

String leer(String rel) {
  final f = File('$raiz/$rel');
  return f.existsSync() ? f.readAsStringSync() : '';
}

ProcessResult git(List<String> args) => Process.runSync(
  'git',
  ['-c', 'core.quotepath=false', ...args],
  workingDirectory: raiz,
  stdoutEncoding: utf8,
  stderrEncoding: utf8,
);

List<String> archivosBajo(String rel, bool Function(String) filtro) {
  final dir = Directory('$raiz/$rel');
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => relativa(f.path))
      .where((r) => !r.contains('/build/') && !r.contains('/.dart_tool/'))
      .where(filtro)
      .toList()
    ..sort();
}

String normalizar(String p) => p.replaceAll(r'\', '/');

String relativa(String absoluta) {
  final a = normalizar(File(absoluta).absolute.path);
  final r = normalizar(raiz);
  if (a.toLowerCase().startsWith('${r.toLowerCase()}/')) {
    return a.substring(r.length + 1);
  }
  return a;
}

void cargarContexto() {
  claudeMd = leer('CLAUDE.md');

  tokensEspaciado = {};
  for (final m in RegExp(
    r'static const double (\w+) = (\d+(?:\.\d+)?);',
  ).allMatches(leer('cupo/lib/theme/app_spacing.dart'))) {
    tokensEspaciado.putIfAbsent(double.parse(m[2]!), () => m[1]!);
  }

  hexDeMarca = {
    for (final m in RegExp(r'#[0-9A-Fa-f]{6}\b').allMatches(claudeMd))
      m[0]!.toUpperCase(),
    '#FFFFFF',
  };

  pruebas = [
    for (final r in archivosBajo('cupo/test', (r) => r.endsWith('.dart')))
      Fuente(r, leer(r), esDart: true),
  ];

  exportsWidgets = leer('cupo/lib/shared/widgets/widgets.dart');

  todasLasMigraciones = [
    for (final r in archivosBajo(
      'supabase/migrations',
      (r) => r.endsWith('.sql'),
    ))
      sinComentariosSql(leer(r)),
  ].join('\n');

  codigoLib = [
    for (final r in archivosBajo('cupo/lib', (r) => r.endsWith('.dart')))
      Fuente(r, leer(r), esDart: true).codigo,
  ].join('\n');
}

/// Pone en blanco los comentarios `--` sin mover los offsets, para que los
/// números de línea sigan apuntando al archivo original.
String sinComentariosSql(String sql) =>
    sql.replaceAllMapped(RegExp(r'--[^\n]*'), (m) => ' ' * m[0]!.length);

// ---------------------------------------------------------------------------
// Reglas
// ---------------------------------------------------------------------------

bool enLib(String r) => r.startsWith('cupo/lib/');
bool enTema(String r) => r.startsWith('cupo/lib/theme/');
bool enPresentacion(String r) =>
    RegExp(r'^cupo/lib/features/[^/]+/presentation/').hasMatch(r) ||
    r.startsWith('cupo/lib/shared/widgets/') ||
    r == 'cupo/lib/main.dart';

const appColors = 'cupo/lib/theme/app_colors.dart';
const appTypography = 'cupo/lib/theme/app_typography.dart';

Iterable<Hallazgo> buscar(
  Fuente f,
  String texto,
  RegExp re,
  String regla,
  Severidad sev,
  String Function(RegExpMatch m) mensaje,
) sync* {
  for (final m in re.allMatches(texto)) {
    yield Hallazgo(regla, sev, f.ruta, f.lineaDe(m.start), mensaje(m));
  }
}

/// Encuentra `Nombre(` y entrega sus argumentos balanceados.
Iterable<({RegExpMatch m, ({int inicio, String texto}) args})> llamadas(
  Fuente f,
  RegExp re,
) sync* {
  for (final m in re.allMatches(f.estructura)) {
    final abre = f.estructura.indexOf('(', m.end - 1);
    if (abre == -1) continue;
    final a = f.argumentos(abre);
    if (a != null) yield (m: m, args: a);
  }
}

Iterable<Hallazgo> reglasDart(Fuente f) sync* {
  final r = f.ruta;
  final est = f.estructura;
  final cod = f.codigo;

  // --- Seguridad: aplica a todo Dart, pruebas incluidas --------------------
  yield* buscar(
    f,
    cod,
    RegExp(r'eyJ[\w-]{10,}\.[\w-]{10,}'),
    'SEG2',
    Severidad.bloqueante,
    (_) =>
        'Hay un JWT/clave escrito en el código. Las credenciales entran por '
        '--dart-define (Env); nunca se suben al repositorio.',
  );
  if (r.startsWith('cupo/')) {
    yield* buscar(
      f,
      cod,
      RegExp(r'service_role'),
      'SEG1',
      Severidad.bloqueante,
      (_) =>
          'La service_role key salta todo el RLS: jamás puede estar en la '
          'app. Lo que necesite privilegios va en una función SQL '
          'security definer.',
    );
  }

  if (!enLib(r)) return;

  // --- R1 Color ------------------------------------------------------------
  if (r != appColors) {
    yield* buscar(
      f,
      est,
      RegExp(
        r'\bColor\s*\(\s*0x[0-9A-Fa-f]+\s*\)|\bColor\.from(?:ARGB|RGBO)\s*\(|'
        r'(?<![\w.])Colors\.(?!transparent\b)[a-zA-Z]\w*',
      ),
      'R1',
      Severidad.bloqueante,
      (m) =>
          'Literal de color «${m[0]}». Usa AppColors.* o '
          'Theme.of(context).colorScheme.*; si el tono no existe, agrégalo '
          'como token en app_colors.dart con su OkLCH y documéntalo en '
          'CLAUDE.md (regla 4).',
    );
  }

  // --- R2 Tipografía -------------------------------------------------------
  if (r != appTypography) {
    yield* buscar(
      f,
      est,
      RegExp(r'\bGoogleFonts\.(?!config\b)\w+|\bfontFamily\s*:'),
      'R2',
      Severidad.bloqueante,
      (m) =>
          '«${m[0]}» fuera de app_typography.dart. Usa '
          'Theme.of(context).textTheme.* o AppTypography.*.',
    );
    yield* buscar(
      f,
      est,
      RegExp(r'(?<![\w.])TextStyle\s*\('),
      'R2',
      Severidad.importante,
      (_) =>
          'TextStyle construido a mano. Parte de un estilo existente: '
          'Theme.of(context).textTheme.* o AppTypography.<estilo>.copyWith(...).',
    );
    yield* buscar(
      f,
      cod,
      RegExp('caveat', caseSensitive: false),
      'R2',
      Severidad.bloqueante,
      (_) =>
          'Caveat solo existe dentro de AppTypography.logo(). Para el '
          'logotipo usa CupoWordmark o CupoLockup.',
    );
    if (!r.startsWith('cupo/lib/shared/widgets/branding/')) {
      yield* buscar(
        f,
        est,
        RegExp(r'\bAppTypography\.(?:logo|wordmark)\b'),
        'R2',
        Severidad.importante,
        (_) =>
            'Estilo de logotipo (Caveat) fuera de los widgets de marca. Solo '
            'puede pintar la palabra «Cupo»: usa CupoWordmark o CupoLockup.',
      );
    }
  }

  // --- R3 fromSeed ---------------------------------------------------------
  yield* buscar(
    f,
    est,
    RegExp(r'\bColorScheme\.fromSeed\b'),
    'R3',
    Severidad.bloqueante,
    (_) =>
        'ColorScheme.fromSeed está prohibido: el esquema es explícito en '
        'AppTheme.colorScheme.',
  );

  // --- R4 Tokens documentados ---------------------------------------------
  if (r == appColors) {
    for (final m in RegExp(r'static const Color (\w+)\s*=').allMatches(est)) {
      if (!claudeMd.contains('`${m[1]}`')) {
        yield Hallazgo(
          'R4',
          Severidad.importante,
          r,
          f.lineaDe(m.start),
          'El token AppColors.${m[1]} no está en la tabla de color de '
              'CLAUDE.md. Todo tono nuevo se documenta ahí (regla 4).',
        );
      }
    }
  }

  if (!enTema(r)) {
    // --- R5 Radio y elevación ----------------------------------------------
    yield* buscar(
      f,
      est,
      RegExp(r'\b(?:BorderRadius|Radius)\.circular\s*\(\s*(\d+(?:\.\d+)?)'),
      'R5',
      Severidad.importante,
      (m) =>
          'Radio literal ${m[1]}. Usa AppTheme.borderRadius (12) o '
          'AppRadius.smAll / mdAll / brandAll.',
    );
    yield* buscar(
      f,
      est,
      RegExp(r'\bBoxShadow\s*\(|\b\w*[eE]levation\s*:\s*(?:[1-9]|0\.\d*[1-9])'),
      'R5',
      Severidad.importante,
      (m) =>
          '«${m[0]!.trim()}»: la elevación por defecto es 0. La jerarquía se '
          'expresa con AppColors.border y backgroundAlt, no con sombras.',
    );

    // --- R6 Espaciado ------------------------------------------------------
    final numero = RegExp(r'(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])');
    for (final ll in llamadas(
      f,
      RegExp(
        r'\bEdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB|fromSTEB)\s*\(',
      ),
    )) {
      for (final n in numero.allMatches(ll.args.texto)) {
        final h = espaciado(f, ll.args.inicio + n.start, n[1]!, 'EdgeInsets');
        if (h != null) yield h;
      }
    }
    for (final m in RegExp(r'\bSizedBox\s*\(([^()]*)').allMatches(est)) {
      for (final n in RegExp(
        r'\b(?:height|width)\s*:\s*(\d+(?:\.\d+)?)(?![\w.])',
      ).allMatches(m[1]!)) {
        final off = m.start + m[0]!.indexOf(m[1]!) + n.start;
        final h = espaciado(f, off, n[1]!, 'SizedBox');
        if (h != null) yield h;
      }
    }
  }

  // --- R8 Tema oscuro ------------------------------------------------------
  yield* buscar(
    f,
    est,
    RegExp(r'\bdarkTheme\s*:\s*(?!AppTheme\.dark\b)|\bColorScheme\.dark\s*\('),
    'R8',
    Severidad.bloqueante,
    (_) =>
        'Tema oscuro improvisado. Si se agrega, se define como AppTheme.dark '
        'con tokens propios en lib/theme/, nunca invirtiendo colores.',
  );
  yield* buscar(
    f,
    est,
    RegExp(r'\bThemeMode\.(?:dark|system)\b'),
    'R8',
    Severidad.importante,
    (_) => 'La app es light-only por ahora (regla 8).',
  );

  // --- R9 Idioma de la UI --------------------------------------------------
  if (enPresentacion(r)) {
    final ingles = RegExp(
      r"\b(the|and|your|you|please|loading|sign (?:in|up|out)|log ?(?:in|out)|"
      r'submit|cancel|continue|password|next|back|save|delete|settings|'
      r'welcome|retry|forgot|required|invalid|failed|try again|search|'
      r'profile|confirm|done)\b',
      caseSensitive: false,
    );
    final usted = RegExp(
      r'\b(usted|ingrese|seleccione|presione|introduzca|escriba|verifique|'
      r'intente|espere|revise|confirme|elija|coloque|inicie|vuelva|su (?:correo|clave|cuenta|teléfono|cédula))\b',
      caseSensitive: false,
    );
    final vocabulario = {
      RegExp(r'\bcontraseña', caseSensitive: false): '«clave»',
      RegExp(r'\be-?mail\b', caseSensitive: false): '«correo»',
    };
    for (final l in f.literales) {
      final t = l.texto;
      if (t.length < 3 || !t.contains(' ') && !t.contains(RegExp('[A-Z]'))) {
        continue; // rutas, claves, identificadores
      }
      final linea = f.lineaDe(l.inicio);
      final txtLinea = f.lineaOriginal(linea).trimLeft();
      if (RegExp(r'^(import|export|part)\b').hasMatch(txtLinea)) continue;
      if (t.startsWith('/') || t.startsWith('package:')) continue;
      final mi = ingles.firstMatch(t);
      if (mi != null) {
        yield Hallazgo(
          'R9',
          Severidad.sugerencia,
          r,
          linea,
          'Posible texto de UI en inglés («${mi[0]}» en «${recortar(t)}»). '
              'La UI va en español (es-VE).',
        );
      }
      final mu = usted.firstMatch(t);
      if (mu != null) {
        yield Hallazgo(
          'R9',
          Severidad.sugerencia,
          r,
          linea,
          '«${mu[0]}» trata de usted; la app tutea («Escribe tu correo»).',
        );
      }
      for (final e in vocabulario.entries) {
        final mv = e.key.firstMatch(t);
        if (mv != null) {
          yield Hallazgo(
            'R9',
            Severidad.sugerencia,
            r,
            linea,
            '«${mv[0]}»: el resto de la app dice ${e.value}.',
          );
        }
      }
    }
  }

  // --- SEG URL de Supabase -------------------------------------------------
  yield* buscar(
    f,
    cod,
    RegExp(r'https?://[a-z0-9-]+\.supabase\.(?:co|in)\b'),
    'SEG2',
    Severidad.bloqueante,
    (_) =>
        'URL del proyecto Supabase escrita en el código. Usa Env.supabaseUrl.',
  );

  // --- ARQ Capas -----------------------------------------------------------
  if (!r.contains('/data/') && r != 'cupo/lib/main.dart') {
    yield* buscar(
      f,
      est,
      RegExp(r'\bSupabase\.instance\b'),
      'ARQ1',
      Severidad.importante,
      (_) =>
          'Acceso directo a Supabase fuera de data/. Las pantallas hablan con '
          'el repositorio de su feature; así el backend se cambia en un solo '
          'archivo.',
    );
  }
  if (RegExp(r'/presentation/').hasMatch(r)) {
    yield* buscar(
      f,
      est,
      RegExp(r"\.(?:from|rpc)\s*\(\s*'"),
      'ARQ1',
      Severidad.importante,
      (_) =>
          'Consulta a Supabase desde la UI. Muévela al repositorio de data/.',
    );
  }
  if (RegExp(r'^cupo/lib/features/[^/]+/domain/').hasMatch(r)) {
    yield* buscar(
      f,
      f.original,
      RegExp(
        r"^import\s+'package:(flutter|supabase_flutter|sqflite|geolocator|flutter_map)/",
        multiLine: true,
      ),
      'ARQ2',
      Severidad.importante,
      (m) =>
          'domain/ importa ${m[1]}. El dominio es Dart puro para poder '
          'probarlo sin Flutter ni red (como resolver_destino.dart).',
    );
  }
  if (r.startsWith('cupo/lib/shared/widgets/') &&
      !r.endsWith('/widgets.dart')) {
    final rel = r.substring('cupo/lib/shared/widgets/'.length);
    if (!exportsWidgets.contains("export '$rel'")) {
      yield Hallazgo(
        'ARQ3',
        Severidad.sugerencia,
        r,
        0,
        "Widget compartido no exportado en shared/widgets/widgets.dart "
            "(agrega export '$rel';).",
      );
    }
  }
  if (r.startsWith('cupo/lib/core/theme/')) {
    yield Hallazgo(
      'ARQ4',
      Severidad.importante,
      r,
      0,
      'El sistema de diseño vive en cupo/lib/theme/, no en core/theme/.',
    );
  }
  yield* buscar(
    f,
    est,
    RegExp(
      r"\.(?:pushNamed|pushReplacementNamed|popAndPushNamed|pushNamedAndRemoveUntil)\s*(?:<[^>]*>)?\s*\(\s*'",
    ),
    'ARQ5',
    Severidad.sugerencia,
    (_) =>
        'Ruta escrita como cadena. Usa las constantes de AuthRoutes; y '
        'recuerda que después del login la pantalla la decide '
        'resolverDestino, no un pushNamed.',
  );

  // --- FLU Ciclo de vida ---------------------------------------------------
  final liberar = {
    'StreamController': 'close',
    'Timer': 'cancel',
    'Timer.periodic': 'cancel',
  };
  for (final m in RegExp(
    r'\b(\w+)\s*=\s*(TextEditingController|FocusNode|AnimationController|'
    r'ScrollController|PageController|TabController|ValueNotifier|'
    r'StreamController|Timer\.periodic|Timer)\b(?:<[^>]*>)?\s*[.(]',
  ).allMatches(est)) {
    final nombre = m[1]!;
    final tipo = m[2]!;
    final metodo = liberar[tipo] ?? 'dispose';
    final libera = RegExp(
      '\\b${RegExp.escape(nombre)}\\b[^;]*?\\.\\.?(?:dispose|close|cancel)\\s*\\(',
    );
    if (!libera.hasMatch(est)) {
      yield Hallazgo(
        'FLU1',
        Severidad.importante,
        r,
        f.lineaDe(m.start),
        '$nombre ($tipo) se crea pero nunca se llama a .$metodo(). Libéralo '
            'en dispose() o queda vivo después de cerrar la pantalla.',
      );
    }
  }
  for (final m in RegExp(r'\.listen\s*\(').allMatches(est)) {
    final antes = est.substring(0, m.start);
    final corte = [
      antes.lastIndexOf(';'),
      antes.lastIndexOf('{'),
      antes.lastIndexOf('}'),
    ].reduce(math.max);
    final sentencia = antes.substring(corte + 1);
    if (sentencia.contains('return') ||
        sentencia.contains('=>') ||
        sentencia.contains('.add(')) {
      continue;
    }
    final asig = RegExp(r'(\w+)\s*(?:\?\?)?(?<![=!<>])=(?![=>])')
        .firstMatch(sentencia);
    if (asig == null) {
      yield Hallazgo(
        'FLU2',
        Severidad.importante,
        r,
        f.lineaDe(m.start),
        'Suscripción sin guardar: no hay forma de cancelarla. Guárdala en un '
            'StreamSubscription y cancélala en dispose().',
      );
    } else {
      final nombre = asig[1]!;
      if (!RegExp('\\b${RegExp.escape(nombre)}\\b[^;]*?\\.cancel\\s*\\(')
          .hasMatch(est)) {
        yield Hallazgo(
          'FLU2',
          Severidad.importante,
          r,
          f.lineaDe(m.start),
          'La suscripción $nombre nunca se cancela. Llama a '
              '$nombre?.cancel() en dispose().',
        );
      }
    }
  }
  for (final ll in llamadas(
    f,
    RegExp(r'\b(?:FutureBuilder|StreamBuilder)\s*(?:<[^>]*>)?\s*\('),
  )) {
    final m = RegExp(r'\b(future|stream)\s*:\s*[\w.?!]+\s*\(')
        .firstMatch(ll.args.texto);
    if (m != null) {
      yield Hallazgo(
        'FLU3',
        Severidad.importante,
        r,
        f.lineaDe(ll.args.inicio + m.start),
        'El ${m[1]} se crea dentro de build: cada reconstrucción relanza la '
            'consulta. Créalo en initState() y guárdalo en un campo.',
      );
    }
  }
  yield* buscar(
    f,
    est,
    RegExp(
      r'\bMediaQuery\.of\s*\(\s*context\s*\)\s*\.\s*(size|padding|viewInsets|viewPadding|textScaler|orientation)\b',
    ),
    'FLU4',
    Severidad.sugerencia,
    (m) =>
        'Usa MediaQuery.${m[1]}Of(context): reconstruye solo cuando cambia '
        'ese dato, no con cualquier cambio de MediaQuery.',
  );
  yield* buscar(
    f,
    est,
    RegExp(r'\bshrinkWrap\s*:\s*true\b'),
    'FLU5',
    Severidad.sugerencia,
    (_) =>
        'shrinkWrap: true mide todos los hijos de golpe. En listas que '
        'pueden crecer, usa ListView.builder dentro de Expanded o slivers.',
  );

  // --- FLU6 Accesibilidad --------------------------------------------------
  for (final ll in llamadas(f, RegExp(r'\bIconButton(?:\.\w+)?\s*\('))) {
    if (!ll.args.texto.contains(RegExp(r'\btooltip\s*:'))) {
      yield Hallazgo(
        'FLU6',
        Severidad.sugerencia,
        r,
        f.lineaDe(ll.m.start),
        'IconButton sin tooltip: el lector de pantalla no sabe qué hace.',
      );
    }
  }
  for (final ll in llamadas(
    f,
    RegExp(r'\bImage\.(?:asset|network|file|memory)\s*\('),
  )) {
    if (!ll.args.texto.contains(
      RegExp(r'\bsemanticLabel\s*:|\bexcludeFromSemantics\s*:\s*true'),
    )) {
      yield Hallazgo(
        'FLU6',
        Severidad.sugerencia,
        r,
        f.lineaDe(ll.m.start),
        'Imagen sin semanticLabel (o excludeFromSemantics: true si es '
            'decorativa).',
      );
    }
  }
  for (final ll in llamadas(f, RegExp(r'\b(?:InkWell|GestureDetector)\s*\('))) {
    final a = ll.args.texto;
    if (a.contains(RegExp(r'\bIcon\s*\(')) &&
        !a.contains(RegExp(r'\bText\s*\(|semanticLabel\s*:|Semantics\s*\(')) &&
        !est
            .substring(math.max(0, ll.m.start - 400), ll.m.start)
            .contains(RegExp(r'\bSemantics\s*\(|\bTooltip\s*\('))) {
      yield Hallazgo(
        'FLU6',
        Severidad.sugerencia,
        r,
        f.lineaDe(ll.m.start),
        'Control táctil que solo tiene un icono y ninguna etiqueta '
            '(Semantics, Tooltip o Icon.semanticLabel). Revisa también que el '
            'área táctil llegue a 48 dp.',
      );
    }
  }

  // --- TST Pruebas ---------------------------------------------------------
  final base = r.split('/').last;
  final tienePrueba = pruebas.any(
    (p) => RegExp('[/\']${RegExp.escape(base)}\'').hasMatch(p.original),
  );
  if (RegExp(r'^cupo/lib/features/[^/]+/domain/').hasMatch(r) && !tienePrueba) {
    yield Hallazgo(
      'TST1',
      Severidad.importante,
      r,
      0,
      'Ninguna prueba importa este archivo de dominio. La lógica pura se '
          'prueba con test() en cupo/test/features/<feature>/ — es la evidencia '
          'del Objetivo 4.',
    );
  }
  if (RegExp(r'/presentation/.*_screens?\.dart$').hasMatch(r) && !tienePrueba) {
    yield Hallazgo(
      'TST2',
      Severidad.sugerencia,
      r,
      0,
      'Pantalla sin prueba de widget. Móntala con montarPantalla() de '
          'cupo/test/soporte/banco_de_pruebas.dart.',
    );
  }
}

Hallazgo? espaciado(Fuente f, int offset, String literal, String donde) {
  final v = double.parse(literal);
  if (v == 0) return null;
  final linea = f.lineaDe(offset);
  final token = tokensEspaciado[v];
  final entero = v == v.roundToDouble();
  if (token != null) {
    return Hallazgo(
      'R6',
      Severidad.sugerencia,
      f.ruta,
      linea,
      '$donde con $literal literal: usa AppSpacing.$token'
          '${donde == 'SizedBox' ? ' (o AppSizes.* si es un tamaño, no una separación)' : ''}.',
    );
  }
  if (entero && v % 4 == 0) {
    return Hallazgo(
      'R6',
      Severidad.sugerencia,
      f.ruta,
      linea,
      '$donde con $literal literal sin token. Si se repite, agrégalo a '
          'AppSpacing (o AppSizes si es un tamaño).',
    );
  }
  return Hallazgo(
    'R6',
    Severidad.importante,
    f.ruta,
    linea,
    '$donde con $literal: el espaciado va en múltiplos de 4 (regla 6)'
        '${donde == 'SizedBox' ? '; si es un tamaño de componente, muévelo a AppSizes' : ''}.',
  );
}

Iterable<Hallazgo> reglasSql(Fuente f, {required bool modificada}) sync* {
  final r = f.ruta;
  final sql = sinComentariosSql(f.original);
  if (modificada) {
    yield Hallazgo(
      'SQL1',
      Severidad.importante,
      r,
      0,
      'Se editó una migración existente. Si ya se aplicó en algún entorno, '
          'el cambio no se ejecuta: crea una migración nueva.',
    );
  }
  for (final m in RegExp(
    r'create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(\w+)',
    caseSensitive: false,
  ).allMatches(sql)) {
    final t = m[1]!;
    if (!RegExp(
      'alter\\s+table\\s+(?:public\\.)?$t\\s+enable\\s+row\\s+level\\s+security',
      caseSensitive: false,
    ).hasMatch(todasLasMigraciones)) {
      yield Hallazgo(
        'SQL2',
        Severidad.bloqueante,
        r,
        f.lineaDe(m.start),
        'La tabla $t no tiene RLS habilitado en ninguna migración. Sin RLS, '
            'la anon key que va dentro de la app la deja abierta a cualquiera.',
      );
    }
  }
  final funciones = RegExp(
    r'create\s+(?:or\s+replace\s+)?function[\s\S]*?\$\w*\$[\s\S]*?\$\w*\$',
    caseSensitive: false,
  );
  for (final m in funciones.allMatches(sql)) {
    final cuerpo = m[0]!.toLowerCase();
    // El encabezado (antes del cuerpo) y la cola pueden traer los atributos.
    final despues = sql.substring(m.end, math.min(sql.length, m.end + 200));
    final todo = '$cuerpo ${despues.toLowerCase()}';
    if (todo.contains('security definer') &&
        !todo.contains(RegExp(r'set\s+search_path'))) {
      yield Hallazgo(
        'SQL3',
        Severidad.importante,
        r,
        f.lineaDe(m.start),
        'Función security definer sin "set search_path = public": es una '
            'puerta para suplantar objetos del esquema.',
      );
    }
  }
  for (final m in RegExp(
    r'create\s+type\s+(\w+)\s+as\s+enum\s*\(([^)]*)\)',
    caseSensitive: false,
  ).allMatches(sql)) {
    for (final v in RegExp(r"'([^']+)'").allMatches(m[2]!)) {
      if (!codigoLib.contains("'${v[1]}'")) {
        yield Hallazgo(
          'SQL4',
          Severidad.importante,
          r,
          f.lineaDe(m.start),
          "El valor '${v[1]}' del enum ${m[1]} no aparece en el código Dart. "
              'Cada enum de PostgreSQL tiene un enum espejo en domain/ con su '
              'campo valor.',
        );
      }
    }
  }
}

Iterable<Hallazgo> reglasDocumento(Fuente f) sync* {
  // Las alternativas de respaldo (sans-serif, Helvetica…) están bien; lo que
  // falla es una pila que no arranca por una familia de la marca.
  final vistos = <String>{};
  for (final m in RegExp(
    r'font-family\s*:\s*([^;}]+)',
    caseSensitive: false,
  ).allMatches(f.original)) {
    final pila = m[1]!.replaceAll(r'\', '').trim();
    final pilaMin = pila.toLowerCase();
    if (RegExp(r'manrope|caveat|^inherit|^var\(').hasMatch(pilaMin)) continue;
    final linea = f.lineaDe(m.start);
    if (!vistos.add('$linea|$pilaMin')) continue;
    yield Hallazgo(
      'DOC1',
      Severidad.importante,
      f.ruta,
      linea,
      'font-family: $pila — sin familia de la marca. Todo el material usa '
          'Manrope; Caveat 700 solo para el logotipo.',
    );
  }
  for (final m in RegExp(r'#[0-9A-Fa-f]{6}\b').allMatches(f.original)) {
    final hex = m[0]!.toUpperCase();
    final linea = f.lineaDe(m.start);
    if (hexDeMarca.contains(hex) || !vistos.add('$linea|$hex')) continue;
    yield Hallazgo(
      'DOC2',
      Severidad.sugerencia,
      f.ruta,
      linea,
      'Color ${m[0]} fuera de la paleta de CLAUDE.md.',
    );
  }
}

String recortar(String t) =>
    t.length > 40 ? '${t.substring(0, 40).replaceAll('\n', ' ')}…' : t;

// ---------------------------------------------------------------------------
// Alcance: qué archivos y qué líneas
// ---------------------------------------------------------------------------

class Alcance {
  Alcance(this.descripcion);

  final String descripcion;

  /// archivo → líneas cambiadas; `null` significa "todas".
  final Map<String, Set<int>?> archivos = {};

  /// Archivos que ya existían y fueron modificados (no agregados).
  final Set<String> modificados = {};

  bool incluye(Hallazgo h) {
    if (!archivos.containsKey(h.archivo)) return false;
    final lineas = archivos[h.archivo];
    return lineas == null || h.linea == 0 || lineas.contains(h.linea);
  }
}

Alcance alcanceDesdeGit(String? base) {
  String ref;
  String desc;
  if (base == null) {
    ref = 'HEAD';
    desc = 'cambios sin commitear respecto de HEAD';
  } else {
    final mb = git(['merge-base', base, 'HEAD']);
    if (mb.exitCode != 0) {
      stderr.writeln('No se encontró la referencia "$base".');
      exit(2);
    }
    ref = (mb.stdout as String).trim();
    desc = 'cambios desde $base (${ref.substring(0, 7)})';
  }
  final alcance = Alcance(desc);

  final estado = git(['diff', '--name-status', ref]);
  for (final l in LineSplitter.split(estado.stdout as String)) {
    final partes = l.split('\t');
    if (partes.length < 2) continue;
    final st = partes.first;
    final ruta = partes.last;
    if (st.startsWith('D')) continue;
    if (st.startsWith('M')) alcance.modificados.add(ruta);
    alcance.archivos[ruta] = <int>{};
  }

  final diff = git(['diff', '--unified=0', '--no-color', ref]);
  String? actual;
  for (final l in LineSplitter.split(diff.stdout as String)) {
    if (l.startsWith('+++ ')) {
      actual = l == '+++ /dev/null' ? null : l.substring(6);
      continue;
    }
    final h = RegExp(r'^@@ -\S+ \+(\d+)(?:,(\d+))? @@').firstMatch(l);
    if (h != null && actual != null) {
      final ini = int.parse(h[1]!);
      final cant = int.parse(h[2] ?? '1');
      final set = alcance.archivos.putIfAbsent(actual, () => <int>{});
      set?.addAll([for (var i = 0; i < cant; i++) ini + i]);
    }
  }

  final nuevos = git(['ls-files', '--others', '--exclude-standard']);
  for (final l in LineSplitter.split(nuevos.stdout as String)) {
    if (l.trim().isNotEmpty) alcance.archivos[l.trim()] = null;
  }
  return alcance;
}

Alcance alcanceTodo() {
  final a = Alcance('repositorio completo (--todo)');
  for (final r in [
    ...archivosBajo('cupo/lib', (r) => r.endsWith('.dart')),
    ...archivosBajo('cupo/test', (r) => r.endsWith('.dart')),
    ...archivosBajo('supabase/migrations', (r) => r.endsWith('.sql')),
    ...archivosBajo('docs', esDocumentoVisual),
  ]) {
    a.archivos[r] = null;
  }
  return a;
}

Alcance alcanceDeRutas(List<String> rutas) {
  final a = Alcance('rutas indicadas: ${rutas.join(', ')}');
  for (final p in rutas) {
    final abs = File(p).absolute.path;
    if (Directory(abs).existsSync()) {
      for (final f in Directory(
        abs,
      ).listSync(recursive: true).whereType<File>()) {
        a.archivos[relativa(f.path)] = null;
      }
    } else if (File(abs).existsSync()) {
      a.archivos[relativa(abs)] = null;
    } else {
      stderr.writeln('No existe: $p');
    }
  }
  return a;
}

bool esDocumentoVisual(String r) =>
    r.endsWith('.html') || r.endsWith('.svg') || r.endsWith('.css');

// ---------------------------------------------------------------------------
// Principal
// ---------------------------------------------------------------------------

void main(List<String> args) {
  final top = Process.runSync('git', [
    'rev-parse',
    '--show-toplevel',
  ], stdoutEncoding: utf8);
  if (top.exitCode != 0) {
    stderr.writeln('Esto tiene que correr dentro del repositorio.');
    exit(2);
  }
  raiz = normalizar((top.stdout as String).trim());
  cargarContexto();

  String? base;
  var todo = false;
  final rutas = <String>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--todo') {
      todo = true;
    } else if (a == '--base' && i + 1 < args.length) {
      base = args[++i];
    } else if (a == '-h' || a == '--help') {
      stdout.writeln(
        'uso: dart verificar_reglas.dart [--base <ref> | --todo] [rutas...]',
      );
      return;
    } else {
      rutas.add(a);
    }
  }

  final alcance = todo
      ? alcanceTodo()
      : rutas.isNotEmpty
      ? alcanceDeRutas(rutas)
      : alcanceDesdeGit(base);

  final hallazgos = <Hallazgo>[];
  var silenciados = 0;
  final revisados = <String>[];

  for (final ruta in alcance.archivos.keys.toList()..sort()) {
    final archivo = File('$raiz/$ruta');
    final nombre = ruta.split('/').last;

    // Secretos que no deben versionarse, cualquiera sea su tipo.
    if (nombre == '.env' || nombre == 'dart_define.json') {
      hallazgos.add(
        Hallazgo(
          'SEG3',
          Severidad.bloqueante,
          ruta,
          0,
          'Archivo de credenciales dentro del cambio. Debe quedar ignorado '
              'por git (.gitignore); solo se versiona la versión .example.',
        ),
      );
      continue;
    }
    if (!archivo.existsSync()) continue;

    final Iterable<Hallazgo> encontrados;
    final Fuente fuente;
    if (ruta.endsWith('.dart')) {
      fuente = Fuente(ruta, archivo.readAsStringSync(), esDart: true);
      encontrados = reglasDart(fuente);
    } else if (ruta.endsWith('.sql') && ruta.startsWith('supabase/')) {
      fuente = Fuente(ruta, archivo.readAsStringSync(), esDart: false);
      encontrados = reglasSql(
        fuente,
        modificada: alcance.modificados.contains(ruta),
      );
    } else if (esDocumentoVisual(ruta)) {
      fuente = Fuente(ruta, archivo.readAsStringSync(), esDart: false);
      encontrados = reglasDocumento(fuente);
    } else {
      continue;
    }
    revisados.add(ruta);

    for (final h in encontrados) {
      if (!alcance.incluye(h)) continue;
      if (silenciado(fuente, h)) {
        silenciados++;
        continue;
      }
      hallazgos.add(h);
    }
  }

  imprimir(alcance, revisados, hallazgos, silenciados);
  if (hallazgos.any((h) => h.severidad == Severidad.bloqueante)) exit(1);
}

bool silenciado(Fuente f, Hallazgo h) {
  if (h.linea == 0) {
    return RegExp('cupo-ignore:\\s*${h.regla}\\b')
        .hasMatch(f.original.split('\n').take(15).join('\n'));
  }
  final marca = RegExp('cupo-ignore:\\s*${h.regla}\\b');
  return marca.hasMatch(f.lineaOriginal(h.linea)) ||
      marca.hasMatch(f.lineaOriginal(h.linea - 1));
}

void imprimir(
  Alcance alcance,
  List<String> revisados,
  List<Hallazgo> hallazgos,
  int silenciados,
) {
  final out = StringBuffer()
    ..writeln('Verificación de reglas de Cupo')
    ..writeln('Alcance: ${alcance.descripcion}')
    ..writeln('Archivos revisados: ${revisados.length}');
  for (final r in revisados) {
    out.writeln('  · $r');
  }
  out.writeln();

  if (hallazgos.isEmpty) {
    out.writeln('Sin hallazgos automáticos.');
  }
  for (final s in Severidad.values) {
    final grupo = hallazgos.where((h) => h.severidad == s).toList()
      ..sort((a, b) {
        final c = a.archivo.compareTo(b.archivo);
        return c != 0 ? c : a.linea.compareTo(b.linea);
      });
    if (grupo.isEmpty) continue;
    out.writeln('${s.etiqueta} (${grupo.length})');
    for (final h in grupo) {
      final donde = h.linea == 0 ? h.archivo : '${h.archivo}:${h.linea}';
      out.writeln('  $donde  [${h.regla}] ${h.mensaje}');
    }
    out.writeln();
  }

  int cuenta(Severidad s) => hallazgos.where((h) => h.severidad == s).length;
  out.writeln(
    'Total: ${cuenta(Severidad.bloqueante)} bloqueantes · '
    '${cuenta(Severidad.importante)} importantes · '
    '${cuenta(Severidad.sugerencia)} sugerencias'
    '${silenciados > 0 ? ' · $silenciados silenciados con cupo-ignore' : ''}',
  );
  stdout.write(out.toString());
}

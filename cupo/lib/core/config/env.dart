/// Configuración que cambia según dónde corre la app.
///
/// Las credenciales **no se escriben en el código ni se suben al repositorio**.
/// Entran por `--dart-define` al compilar:
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// ```
///
/// Para no repetir eso en cada corrida, el proyecto trae
/// `cupo/dart_define.example.json`: se copia a `dart_define.json` (ignorado por
/// git), se llena, y se corre con `--dart-define-from-file=dart_define.json`.
///
/// La `anon key` es pública por diseño: va dentro de la app y cualquiera puede
/// leerla. Lo que protege los datos no es esa clave, es el RLS. La que **nunca**
/// puede entrar aquí es la `service_role key`, que salta el RLS entero.
abstract final class Env {
  /// `const` y no `final`: `String.fromEnvironment` se resuelve al compilar,
  /// así que el valor se conoce en tiempo de compilación.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true` cuando las dos credenciales llegaron.
  ///
  /// `String.fromEnvironment` devuelve cadena vacía —no `null`— cuando la
  /// variable no se pasó. Por eso se compara con `isEmpty` y no con `== null`:
  /// el operador `??` tampoco serviría, porque solo se dispara ante `null`.
  static bool get estaConfigurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Mensaje para la pantalla de arranque cuando falta la configuración.
  static const String ayudaConfiguracion =
      'Faltan SUPABASE_URL y SUPABASE_ANON_KEY.\n\n'
      'Copia dart_define.example.json a dart_define.json, llénalo con los '
      'datos de tu proyecto en Supabase y corre:\n\n'
      'flutter run --dart-define-from-file=dart_define.json';
}

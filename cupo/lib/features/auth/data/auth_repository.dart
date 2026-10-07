import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/rol_usuario.dart';
import '../domain/usuario.dart';

/// Error de autenticación ya traducido a algo que se le puede mostrar a una
/// persona. Las pantallas atrapan esto, no la `AuthException` cruda.
class AuthFallo implements Exception {
  const AuthFallo(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Todo el trato con Supabase Auth y con la fila de `public.usuarios`.
///
/// Las pantallas no conocen Supabase: hablan con esta clase. Así el día que
/// cambie el backend —ya pasó una vez, de Firebase a Supabase— solo cambia
/// este archivo.
class AuthRepository {
  AuthRepository({SupabaseClient? cliente}) : _inyectado = cliente;

  final SupabaseClient? _inyectado;

  /// El cliente se resuelve al usarlo, no al construir el repositorio.
  ///
  /// `Supabase.instance` revienta si todavía no se llamó a `initialize`, así
  /// que resolverlo en el constructor obligaría a levantar Supabase en cada
  /// prueba de widget, incluso en las que nunca tocan la red.
  SupabaseClient get _db => _inyectado ?? Supabase.instance.client;

  // --- Sesión ---------------------------------------------------------------

  /// La sesión actual, o `null` si nadie entró.
  ///
  /// Es una lectura instantánea de memoria, no una consulta: por eso devuelve
  /// el valor directo y no un `Future`.
  Session? get sesionActual => _db.auth.currentSession;

  String? get idUsuarioActual => _db.auth.currentUser?.id;

  /// Los cambios de sesión a lo largo del tiempo: entrar, salir, refrescar el
  /// token.
  ///
  /// Es un **`Stream`** y no un `Future` porque emite muchos eventos: cada vez
  /// que la sesión cambia llega uno nuevo. Un `Future` se completaría una sola
  /// vez y la app nunca se enteraría del logout.
  Stream<AuthState> get cambiosDeSesion => _db.auth.onAuthStateChange;

  // --- Registro y entrada ---------------------------------------------------

  /// Crea la cuenta. El trigger `crear_usuario()` inserta la fila de
  /// `usuarios` y la del subtipo dentro de la misma transacción, así que al
  /// volver de aquí el perfil ya existe.
  ///
  /// El [rol] viaja en `data` y llega a PostgreSQL como `raw_user_meta_data`.
  /// Es metadato que controla el usuario, por eso el trigger solo acepta
  /// 'estudiante' y 'conductor': `administrador` por esta vía se ignora.
  ///
  /// Devuelve `Future<Usuario>` —no `Usuario`— porque el cuerpo está marcado
  /// `async`: toda función `async` envuelve su retorno en un `Future`, aunque
  /// el `return` sea de un valor simple.
  Future<Usuario> registrar({
    required String email,
    required String clave,
    required RolUsuario rol,
    String nombres = '',
    String apellidos = '',
    String? telefono,
  }) async {
    try {
      final respuesta = await _db.auth.signUp(
        email: email.trim(),
        password: clave,
        data: {
          'rol': rol.valor,
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          if (telefono != null) 'telefono': telefono.trim(),
        },
      );

      // Si el proyecto exige confirmar el correo, signUp devuelve usuario pero
      // no sesión, y todavía no se puede leer la fila (el RLS pide auth.uid()).
      if (respuesta.session == null) {
        throw const AuthFallo(
          'Te mandamos un correo para confirmar la cuenta. Ábrelo y vuelve a '
          'entrar.',
        );
      }

      return await cargarUsuarioActual();
    } on AuthException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  /// Entra con correo y clave, y sella el último acceso.
  Future<Usuario> entrar({
    required String email,
    required String clave,
  }) async {
    try {
      await _db.auth.signInWithPassword(
        email: email.trim(),
        password: clave,
      );

      final usuario = await cargarUsuarioActual();

      // No se hace `await`: que el sello de acceso falle no debe impedir
      // entrar. `ignore()` silencia el aviso del analizador sobre el future
      // suelto, que aquí es intencional.
      _db.rpc('registrar_acceso').ignore();

      return usuario;
    } on AuthException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  /// Entra con Google.
  ///
  /// Abre el navegador del sistema y vuelve a la app por un enlace profundo.
  /// Para que el regreso funcione hacen falta dos cosas fuera de Dart:
  ///
  ///  1. Habilitar Google en *Authentication → Providers* del panel de
  ///     Supabase, con el `client id` y el `secret` de Google Cloud.
  ///  2. Declarar el esquema `io.supabase.cupo` en `AndroidManifest.xml`
  ///     (ya está declarado) y registrarlo como *Redirect URL* en Supabase:
  ///     `io.supabase.cupo://login-callback/`.
  ///
  /// No devuelve el usuario: el regreso llega por [cambiosDeSesion], y es el
  /// `AuthGate` quien reacciona.
  ///
  /// Ojo con el rol: por OAuth no viaja `raw_user_meta_data`, así que el
  /// trigger crea la cuenta como estudiante. El conductor que entre por Google
  /// queda como estudiante — por eso el registro de conductor va por correo y
  /// clave hasta que se resuelva (ver TODO.md).
  Future<void> entrarConGoogle() async {
    try {
      await _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.cupo://login-callback/',
      );
    } on AuthException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  Future<void> salir() => _db.auth.signOut();

  /// Manda el correo de recuperación de clave.
  Future<void> recuperarClave(String email) async {
    try {
      await _db.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  // --- La fila de usuarios --------------------------------------------------

  /// Lee `public.usuarios` para la sesión actual.
  ///
  /// Esta consulta **es parte del login**, no algo posterior: Supabase Auth
  /// responde quién eres, pero el rol y el estado viven aquí, y sin ellos la
  /// app no sabe a qué pantalla ir (apartado 5 del modelo).
  ///
  /// No hace falta filtrar por id —el RLS ya limita la consulta a la propia
  /// fila—, pero el `.eq()` se deja explícito: una consulta que depende solo
  /// del RLS es difícil de leer.
  Future<Usuario> cargarUsuarioActual() async {
    final id = idUsuarioActual;

    // `id` es `String?`. Se copia a una variable local antes de comprobarlo
    // porque Dart solo promueve a no-nulo lo que no puede cambiar entre la
    // comprobación y el uso.
    if (id == null) {
      throw const AuthFallo('No hay sesión abierta.');
    }

    final fila = await _db
        .from('usuarios')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (fila == null) {
      throw const AuthFallo(
        'La cuenta existe pero no tiene perfil. Avisa al administrador.',
      );
    }

    return Usuario.fromMap(fila);
  }

  /// La propia fila de `usuarios`, en vivo.
  ///
  /// Otro **`Stream`**, y por un motivo concreto: si el administrador suspende
  /// la cuenta mientras la persona tiene la app abierta, la app se entera y la
  /// saca. Con un `Future` se enteraría en el próximo arranque, no antes.
  Stream<Usuario> observarUsuario(String id) {
    return _db
        .from('usuarios')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((filas) => Usuario.fromMap(filas.first));
  }

  // --- Transiciones de estado ----------------------------------------------

  /// `perfil_incompleto` | `rechazada` → `pendiente`.
  ///
  /// Va por RPC y no por `update` porque los privilegios por columna le
  /// revocan al usuario la escritura de `estado`. La validación de qué datos
  /// hacen falta está en la función SQL, del lado en que no se puede saltar.
  Future<void> enviarARevision() async {
    try {
      await _db.rpc('enviar_a_revision');
    } on PostgrestException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  /// Marca `onboarding_completo = true`. Misma razón para ir por RPC.
  Future<void> completarOnboarding() async {
    try {
      await _db.rpc('completar_onboarding');
    } on PostgrestException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  /// Actualiza los datos personales. Estas columnas sí las puede escribir el
  /// propio usuario (ver el `grant update (...)` de la migración 06).
  Future<void> guardarDatosPersonales({
    required String nombres,
    required String apellidos,
    required String cedula,
    required String telefono,
  }) async {
    final id = idUsuarioActual;
    if (id == null) throw const AuthFallo('No hay sesión abierta.');

    try {
      await _db
          .from('usuarios')
          .update({
            'nombres': nombres.trim(),
            'apellidos': apellidos.trim(),
            'cedula': cedula.trim(),
            'telefono': telefono.trim(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw AuthFallo(_traducir(e));
    }
  }

  // --- Errores --------------------------------------------------------------

  /// Traduce el error del backend a algo que se le pueda mostrar a alguien.
  ///
  /// Supabase responde en inglés y con jerga; la app habla español (es-VE).
  String _traducir(Object e) {
    final crudo = switch (e) {
      AuthException(:final message) => message,
      PostgrestException(:final message) => message,
      _ => e.toString(),
    };
    final texto = crudo.toLowerCase();

    if (texto.contains('invalid login credentials')) {
      return 'Ese correo o esa clave no coinciden.';
    }
    if (texto.contains('email not confirmed')) {
      return 'Todavía no confirmaste el correo. Revisa tu bandeja.';
    }
    if (texto.contains('user already registered') ||
        texto.contains('already been registered')) {
      return 'Ya hay una cuenta con ese correo. Entra en vez de registrarte.';
    }
    if (texto.contains('password should be at least')) {
      return 'La clave necesita al menos 6 caracteres.';
    }
    if (texto.contains('usuarios_cedula_key')) {
      return 'Esa cédula ya está registrada.';
    }
    if (texto.contains('usuarios_telefono_key')) {
      return 'Ese teléfono ya está registrado.';
    }
    if (texto.contains('rate limit')) {
      return 'Demasiados intentos seguidos. Espera un momento.';
    }
    if (texto.contains('failed host lookup') ||
        texto.contains('socketexception')) {
      return 'No hay conexión. Revisa tus datos o el wifi.';
    }

    // Las excepciones de las funciones SQL ya vienen redactadas en español
    // («Faltan los datos de la licencia»), así que se muestran tal cual.
    return crudo;
  }
}

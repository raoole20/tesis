/// Nombres de ruta del primer ingreso.
///
/// Las cuatro pantallas de «Primer ingreso» (L1–L4) y el destino al que se
/// entra una vez autenticado.
abstract final class AuthRoutes {
  /// L1 — Bienvenida.
  static const String welcome = '/';

  /// L2 — Crear cuenta.
  static const String signUp = '/registro';

  /// L3 — Verificar teléfono.
  static const String verifyPhone = '/verificar';

  /// L4 — Iniciar sesión.
  static const String signIn = '/entrar';
}

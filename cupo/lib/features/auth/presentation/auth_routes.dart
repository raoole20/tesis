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

  /// 03 — Marcar domicilio (Onboarding).
  static const String setHome = '/onboarding/domicilio';

  /// 05 — Mis días y turno (Búsqueda).
  static const String searchFilters = '/buscar';

  /// 10 — Pantalla principal del estudiante (Home).
  static const String home = '/home';
}

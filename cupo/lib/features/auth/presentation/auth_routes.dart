/// Nombres de ruta del primer ingreso.
///
/// Solo las pantallas de antes de la sesión. Registro e inicio de sesión no
/// tienen ruta: son contenidos de la hoja de `WelcomeScreen`, que crece en
/// vez de navegar. Lo que viene después NO tiene
/// ruta con nombre: lo decide el `AuthGate` a partir del estado de la cuenta
/// (apartado 6 del modelo de datos). Si el destino se pudiera empujar por
/// nombre, habría dos fuentes de verdad para lo mismo.
abstract final class AuthRoutes {
  /// L3 — Verificar teléfono. **Fuera del flujo por ahora**: la verificación
  /// por WhatsApp exige un proveedor de SMS pago (Twilio o similar) conectado
  /// a Supabase Auth. La pantalla queda construida para cuando se contrate.
  static const String verifyPhone = '/verificar';
}

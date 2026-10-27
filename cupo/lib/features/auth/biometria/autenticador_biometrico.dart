import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Lo único que [ServicioHuella] necesita del lector de huellas.
///
/// Es una interfaz para que la lógica se pruebe sin teléfono: las pruebas
/// pasan un doble que aprueba, cancela o lanza el error que haga falta.
abstract interface class AutenticadorBiometrico {
  /// `true` si el teléfono tiene lector biométrico. Puede que no haya huellas
  /// registradas todavía: eso se avisa al pedir la huella, con su mensaje.
  Future<bool> disponible();

  /// Muestra el aviso del sistema con [motivo] y espera la huella.
  ///
  /// Devuelve `true` si se reconoció y `false` si el sistema la rechazó sin
  /// más detalle. Cancelar, el bloqueo por intentos o no tener huellas
  /// registradas llegan como [LocalAuthException].
  Future<bool> autenticar(String motivo);
}

/// La implementación real, sobre `local_auth`.
///
/// En Android exige que `MainActivity` herede de `FlutterFragmentActivity`
/// y el permiso `USE_BIOMETRIC` en el manifiesto.
class AutenticadorLocalAuth implements AutenticadorBiometrico {
  AutenticadorLocalAuth({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> disponible() async {
    // En el navegador no hay huella; `local_auth` ni siquiera tiene
    // implementación web.
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> autenticar(String motivo) {
    return _localAuth.authenticate(
      localizedReason: motivo,
      // Solo huella (o la biometría fuerte del teléfono), no el PIN: quien
      // conoce el PIN del teléfono no debe poder entrar a la cuenta.
      biometricOnly: true,
      // Los textos del aviso del sistema; sin esto salen en inglés.
      authMessages: const [
        AndroidAuthMessages(
          signInTitle: 'Tu huella',
          signInHint: 'Toca el sensor de huellas',
          cancelButton: 'Cancelar',
        ),
      ],
    );
  }
}

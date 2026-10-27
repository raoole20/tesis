import 'package:local_auth/local_auth.dart';

import '../data/auth_repository.dart';
import 'almacen_seguro.dart';
import 'autenticador_biometrico.dart';

/// Comprueba o abre una sesión con correo y clave. En la app es
/// `AuthRepository.verificarClave` (al activar) o `AuthRepository.entrar` (al
/// entrar con la huella); en las pruebas, una función cualquiera.
///
/// Si las credenciales no sirven, lanza [AuthFallo].
typedef UsarCredenciales = Future<void> Function(String email, String clave);

/// Cómo terminó un pedido de huella.
sealed class ResultadoHuella {
  const ResultadoHuella();
}

/// La huella se reconoció y lo que seguía (guardar o entrar) salió bien.
final class HuellaAprobada extends ResultadoHuella {
  const HuellaAprobada();
}

/// La persona cerró el aviso, o el sistema lo cerró (la app pasó a segundo
/// plano). No es un error: no se muestra nada.
final class HuellaCancelada extends ResultadoHuella {
  const HuellaCancelada();
}

/// Algo impidió seguir. [mensaje] ya está en español para mostrarlo tal cual.
final class HuellaRechazada extends ResultadoHuella {
  const HuellaRechazada(this.mensaje, {this.seDesactivo = false});

  final String mensaje;

  /// `true` si, además, se borró lo guardado y la huella quedó apagada.
  final bool seDesactivo;
}

/// Entrar con huella: activarla, usarla y apagarla.
///
/// **Por qué se guarda la clave.** Supabase revoca el token de refresco al
/// cerrar sesión, así que guardar la sesión no serviría para volver a entrar
/// después de «Cerrar sesión». Lo que sí sirve es lo mismo que escribiría la
/// persona: correo y clave. Se guardan cifrados con el Keystore de Android y
/// solo se leen después de que el lector reconoce la huella.
///
/// **Un solo correo por teléfono.** Lo guardado pertenece a un correo. Si
/// otra persona entra con su clave en el mismo teléfono, la huella guardada
/// no se le activa: la pantalla de ingreso ofrece «Entrar con huella» con el
/// correo a la vista, para que nadie entre a una cuenta ajena sin darse
/// cuenta, y en «Tu cuenta» el interruptor de esa otra persona sale apagado.
/// Si ella la activa, reemplaza a la anterior.
///
/// «Cerrar sesión» no borra nada: justamente es lo que permite volver a
/// entrar con la huella.
class ServicioHuella {
  ServicioHuella({required this._autenticador, required this._almacen});

  /// El de verdad: `local_auth` y `flutter_secure_storage`.
  factory ServicioHuella.delDispositivo() => ServicioHuella(
    autenticador: AutenticadorLocalAuth(),
    almacen: AlmacenSeguroDelSistema(),
  );

  final AutenticadorBiometrico _autenticador;
  final AlmacenSeguro _almacen;

  static const claveCorreo = 'huella.correo';
  static const claveClave = 'huella.clave';

  /// La marca «huella activa». Guarda el correo al que pertenece: si no
  /// coincide con [claveCorreo], lo guardado no se usa.
  static const claveActiva = 'huella.activa_para';

  static const motivoActivar = 'Confirma tu huella para activarla';
  static const motivoEntrar = 'Usa tu huella para entrar a Cupo';

  static const mensajeClaveCambio =
      'Tu clave cambió. Entra con tu clave y vuelve a activar la huella.';
  static const mensajeClaveEquivocada =
      'Esa no es tu clave. Revísala e inténtalo otra vez.';

  /// `true` si el teléfono tiene lector biométrico.
  Future<bool> disponible() async {
    try {
      return await _autenticador.disponible();
    } catch (_) {
      return false;
    }
  }

  /// El correo con el que se puede entrar con huella, o `null` si no está
  /// activa.
  Future<String?> correoActivo() async {
    try {
      final correo = await _almacen.leer(claveCorreo);
      final activaPara = await _almacen.leer(claveActiva);
      if (correo == null || activaPara == null) return null;
      return _mismoCorreo(correo, activaPara) ? correo : null;
    } catch (_) {
      // Si el almacén no se puede descifrar (por ejemplo, tras restaurar un
      // respaldo en otro teléfono), es como si no hubiera nada.
      return null;
    }
  }

  /// `true` si la huella está activa y es de [email].
  Future<bool> activaPara(String email) async {
    final correo = await correoActivo();
    return correo != null && _mismoCorreo(correo, email);
  }

  /// Paso 1 de activar: que la persona ponga el dedo. Así se sabe, antes de
  /// pedir la clave, que el lector funciona y que hay una huella registrada.
  Future<ResultadoHuella> confirmarHuella() => _pedirHuella(motivoActivar);

  /// Paso 2 de activar: comprueba la clave con [verificar] y, si es la buena,
  /// la guarda junto con el correo y la marca.
  ///
  /// Lanza [AuthFallo] si la clave no sirve; en ese caso no se guarda nada.
  Future<void> activar({
    required String email,
    required String clave,
    required UsarCredenciales verificar,
  }) async {
    final correo = email.trim();
    try {
      await verificar(correo, clave);
    } on AuthFallo catch (e) {
      if (e.credencialesInvalidas) {
        throw const AuthFallo(
          mensajeClaveEquivocada,
          credencialesInvalidas: true,
        );
      }
      rethrow;
    }

    // La marca va de última: si algo falla a mitad, no queda una huella
    // «activa» con datos a medias.
    await _almacen.borrar(claveActiva);
    await _almacen.escribir(claveCorreo, correo);
    await _almacen.escribir(claveClave, clave);
    await _almacen.escribir(claveActiva, correo);
  }

  /// Apaga la huella y borra lo guardado. No pide la huella: apagarla nunca
  /// expone nada.
  Future<void> desactivar() async {
    // La marca va primero, por la misma razón que en [activar].
    await _almacen.borrar(claveActiva);
    await _almacen.borrar(claveClave);
    await _almacen.borrar(claveCorreo);
  }

  /// Pide la huella, lee lo guardado y entra con [entrar].
  ///
  /// Si Supabase dice que la clave ya no sirve (la cambiaron desde otro
  /// lado), borra lo guardado y lo avisa con [mensajeClaveCambio]. Si el
  /// problema es la red, conserva todo: la clave sigue siendo buena.
  Future<ResultadoHuella> entrar({required UsarCredenciales entrar}) async {
    if (await correoActivo() == null) {
      return const HuellaRechazada(
        'La huella no está activa en este teléfono. Entra con tu clave.',
        seDesactivo: true,
      );
    }

    final huella = await _pedirHuella(motivoEntrar);
    if (huella is! HuellaAprobada) return huella;

    final String? correo;
    final String? clave;
    try {
      correo = await _almacen.leer(claveCorreo);
      clave = await _almacen.leer(claveClave);
    } catch (_) {
      return _desactivarPor(
        'No pudimos leer tus datos guardados. Entra con tu clave y vuelve a '
        'activar la huella.',
      );
    }
    if (correo == null || clave == null) {
      return _desactivarPor(
        'Faltan tus datos guardados. Entra con tu clave y vuelve a activar '
        'la huella.',
      );
    }

    try {
      await entrar(correo, clave);
      return const HuellaAprobada();
    } on AuthFallo catch (e) {
      if (e.credencialesInvalidas) return _desactivarPor(mensajeClaveCambio);
      return HuellaRechazada(e.mensaje);
    }
  }

  Future<HuellaRechazada> _desactivarPor(String mensaje) async {
    try {
      await desactivar();
    } catch (_) {
      // Si ni siquiera se puede borrar, el mensaje sigue siendo el mismo.
    }
    return HuellaRechazada(mensaje, seDesactivo: true);
  }

  Future<ResultadoHuella> _pedirHuella(String motivo) async {
    try {
      final reconocida = await _autenticador.autenticar(motivo);
      return reconocida
          ? const HuellaAprobada()
          : const HuellaRechazada(
              'No reconocimos la huella. Inténtalo otra vez.',
            );
    } on LocalAuthException catch (e) {
      return _traducir(e.code);
    } catch (_) {
      return const HuellaRechazada(
        'No se pudo leer la huella. Entra con tu clave.',
      );
    }
  }

  /// Los errores del lector, en español y sin jerga.
  static ResultadoHuella _traducir(LocalAuthExceptionCode codigo) {
    return switch (codigo) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout ||
      LocalAuthExceptionCode.userRequestedFallback ||
      LocalAuthExceptionCode.authInProgress => const HuellaCancelada(),
      LocalAuthExceptionCode.temporaryLockout => const HuellaRechazada(
        'Demasiados intentos fallidos. Espera unos segundos e inténtalo otra '
        'vez.',
      ),
      LocalAuthExceptionCode.biometricLockout => const HuellaRechazada(
        'La huella quedó bloqueada por demasiados intentos. Desbloquea el '
        'teléfono con tu PIN o patrón y vuelve a intentarlo.',
      ),
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noCredentialsSet => const HuellaRechazada(
        'No tienes huellas registradas en este teléfono. Agrega una en los '
        'ajustes de seguridad y vuelve a intentarlo.',
      ),
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
      LocalAuthExceptionCode.uiUnavailable => const HuellaRechazada(
        'El lector de huellas no está disponible ahora. Entra con tu clave.',
      ),
      _ => const HuellaRechazada(
        'No se pudo leer la huella. Entra con tu clave.',
      ),
    };
  }

  static bool _mismoCorreo(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}

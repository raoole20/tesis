import 'package:cupo/features/auth/biometria/servicio_huella.dart';
import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import '../../../soporte/huella_falsa.dart';

/// Credenciales de mentira: nada de esto existe en Supabase.
const _correo = 'genesis@ejemplo.com';
const _clave = 'clave-de-prueba';

void main() {
  late AutenticadorFalso lector;
  late AlmacenEnMemoria almacen;
  late ServicioHuella servicio;

  setUp(() {
    lector = AutenticadorFalso();
    almacen = AlmacenEnMemoria();
    servicio = ServicioHuella(autenticador: lector, almacen: almacen);
  });

  /// Deja la huella activa para [correo], como si ya se hubiera activado.
  Future<void> activarPara(String correo, {String clave = _clave}) {
    return servicio.activar(
      email: correo,
      clave: clave,
      verificar: (_, _) async {},
    );
  }

  Future<void> credencialesInvalidas(String _, String _) async =>
      throw const AuthFallo('no coinciden', credencialesInvalidas: true);

  group('activar', () {
    test('confirma la huella con el motivo de activar', () async {
      final r = await servicio.confirmarHuella();

      expect(r, isA<HuellaAprobada>());
      expect(lector.pedidos, [ServicioHuella.motivoActivar]);
    });

    test('verifica la clave y guarda correo, clave y marca', () async {
      final verificadas = <String>[];

      await servicio.activar(
        email: '  $_correo ',
        clave: _clave,
        verificar: (email, clave) async => verificadas.add('$email:$clave'),
      );

      expect(verificadas, ['$_correo:$_clave']);
      expect(almacen.datos, {
        ServicioHuella.claveCorreo: _correo,
        ServicioHuella.claveClave: _clave,
        ServicioHuella.claveActiva: _correo,
      });
      expect(await servicio.correoActivo(), _correo);
      expect(await servicio.activaPara('GENESIS@ejemplo.com'), isTrue);
    });

    test('con la clave equivocada no guarda nada', () async {
      await expectLater(
        servicio.activar(
          email: _correo,
          clave: 'otra',
          verificar: credencialesInvalidas,
        ),
        throwsA(
          isA<AuthFallo>().having(
            (e) => e.mensaje,
            'mensaje',
            ServicioHuella.mensajeClaveEquivocada,
          ),
        ),
      );
      expect(almacen.datos, isEmpty);
      expect(await servicio.correoActivo(), isNull);
    });

    test('si falla la red, deja pasar el error tal cual', () async {
      await expectLater(
        servicio.activar(
          email: _correo,
          clave: _clave,
          verificar: (_, _) async => throw const AuthFallo('No hay conexión.'),
        ),
        throwsA(
          isA<AuthFallo>().having(
            (e) => e.mensaje,
            'mensaje',
            'No hay '
                'conexión.',
          ),
        ),
      );
      expect(almacen.datos, isEmpty);
    });

    test('cancelar la huella no es un error', () async {
      lector.respuesta = const LocalAuthException(
        code: LocalAuthExceptionCode.userCanceled,
      );

      expect(await servicio.confirmarHuella(), isA<HuellaCancelada>());
    });
  });

  group('entrar', () {
    test('sin huella activa no pide la huella', () async {
      final r = await servicio.entrar(entrar: (_, _) async {});

      expect(r, isA<HuellaRechazada>());
      expect(lector.pedidos, isEmpty);
    });

    test('con la huella reconocida entra con lo guardado', () async {
      await activarPara(_correo);
      final usadas = <String>[];

      final r = await servicio.entrar(
        entrar: (email, clave) async => usadas.add('$email:$clave'),
      );

      expect(r, isA<HuellaAprobada>());
      expect(lector.pedidos, [ServicioHuella.motivoEntrar]);
      expect(usadas, ['$_correo:$_clave']);
    });

    test('si la clave cambió, borra lo guardado y lo avisa', () async {
      await activarPara(_correo);

      final r = await servicio.entrar(entrar: credencialesInvalidas);

      expect(
        r,
        isA<HuellaRechazada>()
            .having(
              (h) => h.mensaje,
              'mensaje',
              ServicioHuella.mensajeClaveCambio,
            )
            .having((h) => h.seDesactivo, 'seDesactivo', isTrue),
      );
      expect(almacen.datos, isEmpty);
      expect(await servicio.correoActivo(), isNull);
    });

    test('si falla la red, conserva la huella', () async {
      await activarPara(_correo);

      final r = await servicio.entrar(
        entrar: (_, _) async => throw const AuthFallo('No hay conexión.'),
      );

      expect(
        r,
        isA<HuellaRechazada>()
            .having((h) => h.mensaje, 'mensaje', 'No hay conexión.')
            .having((h) => h.seDesactivo, 'seDesactivo', isFalse),
      );
      expect(await servicio.correoActivo(), _correo);
    });

    test('cancelar no entra ni borra nada', () async {
      await activarPara(_correo);
      lector.respuesta = const LocalAuthException(
        code: LocalAuthExceptionCode.userCanceled,
      );
      var entradas = 0;

      final r = await servicio.entrar(entrar: (_, _) async => entradas++);

      expect(r, isA<HuellaCancelada>());
      expect(entradas, 0);
      expect(await servicio.correoActivo(), _correo);
    });

    test('una huella no reconocida no entra', () async {
      await activarPara(_correo);
      lector.respuesta = false;
      var entradas = 0;

      final r = await servicio.entrar(entrar: (_, _) async => entradas++);

      expect(r, isA<HuellaRechazada>());
      expect(entradas, 0);
    });

    test('si falta la clave guardada, se desactiva', () async {
      await activarPara(_correo);
      almacen.datos.remove(ServicioHuella.claveClave);
      var entradas = 0;

      final r = await servicio.entrar(entrar: (_, _) async => entradas++);

      expect(
        r,
        isA<HuellaRechazada>().having(
          (h) => h.seDesactivo,
          'seDesactivo',
          isTrue,
        ),
      );
      expect(entradas, 0);
      expect(almacen.datos, isEmpty);
    });

    test('si lo guardado no se puede descifrar, no se ofrece', () async {
      await activarPara(_correo);
      almacen.fallaAlLeer = true;

      expect(await servicio.correoActivo(), isNull);
    });
  });

  group('errores del lector', () {
    Future<String> mensajePara(LocalAuthExceptionCode codigo) async {
      lector.respuesta = LocalAuthException(code: codigo);
      final r = await servicio.confirmarHuella();
      return (r as HuellaRechazada).mensaje;
    }

    test('bloqueo temporal por intentos', () async {
      expect(
        await mensajePara(LocalAuthExceptionCode.temporaryLockout),
        contains('Espera unos segundos'),
      );
    });

    test('bloqueo hasta desbloquear el teléfono', () async {
      expect(
        await mensajePara(LocalAuthExceptionCode.biometricLockout),
        contains('PIN o patrón'),
      );
    });

    test('sin huellas registradas', () async {
      expect(
        await mensajePara(LocalAuthExceptionCode.noBiometricsEnrolled),
        contains('No tienes huellas registradas'),
      );
    });

    test('el sistema cerró el aviso: cuenta como cancelado', () async {
      lector.respuesta = const LocalAuthException(
        code: LocalAuthExceptionCode.systemCanceled,
      );
      expect(await servicio.confirmarHuella(), isA<HuellaCancelada>());
    });

    test('un error cualquiera no revienta', () async {
      lector.respuesta = Exception('canal roto');
      expect(await servicio.confirmarHuella(), isA<HuellaRechazada>());
    });
  });

  group('desactivar', () {
    test('borra todo sin pedir la huella', () async {
      await activarPara(_correo);

      await servicio.desactivar();

      expect(almacen.datos, isEmpty);
      expect(lector.pedidos, isEmpty);
      expect(await servicio.correoActivo(), isNull);
    });
  });

  group('otro correo', () {
    test('la huella de una cuenta no está activa para otra', () async {
      await activarPara(_correo);

      expect(await servicio.activaPara('andres@ejemplo.com'), isFalse);
      // Sigue ofreciéndose, pero con su propio correo.
      expect(await servicio.correoActivo(), _correo);
    });

    test('activarla con otra cuenta reemplaza la anterior', () async {
      await activarPara(_correo);
      await activarPara('andres@ejemplo.com', clave: 'otra-clave-de-prueba');

      expect(await servicio.correoActivo(), 'andres@ejemplo.com');
      expect(await servicio.activaPara(_correo), isFalse);
      expect(almacen.datos[ServicioHuella.claveClave], 'otra-clave-de-prueba');
    });

    test('una marca de otro correo no cuenta como activa', () async {
      almacen.datos
        ..[ServicioHuella.claveCorreo] = _correo
        ..[ServicioHuella.claveClave] = _clave
        ..[ServicioHuella.claveActiva] = 'andres@ejemplo.com';

      expect(await servicio.correoActivo(), isNull);
    });
  });

  group('disponible', () {
    test('refleja si hay lector', () async {
      expect(await servicio.disponible(), isTrue);
      lector.hayLector = false;
      expect(await servicio.disponible(), isFalse);
    });
  });
}

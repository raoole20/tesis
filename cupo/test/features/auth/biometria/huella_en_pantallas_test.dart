import 'package:cupo/features/auth/biometria/servicio_huella.dart';
import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:cupo/features/auth/domain/usuario.dart';
import 'package:cupo/features/auth/presentation/cuenta/boton_de_cuenta.dart';
import 'package:cupo/features/auth/presentation/sign_in_form.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../../soporte/banco_de_pruebas.dart';
import '../../../soporte/huella_falsa.dart';

/// Credenciales de mentira: nada de esto existe en Supabase.
const _correo = 'genesis@ejemplo.com';
const _clave = 'clave-de-prueba';

/// Lo que lanza `local_auth` cuando la persona cierra el aviso.
const _cancelado = LocalAuthException(
  code: LocalAuthExceptionCode.userCanceled,
);

/// No toca Supabase: anota lo que se le pide y solo acepta [_clave].
class _RepoFalso extends AuthRepository {
  static const claveBuena = _clave;

  final entradas = <String>[];
  final verificaciones = <String>[];

  Never _rechazar() =>
      throw const AuthFallo('no coinciden', credencialesInvalidas: true);

  @override
  Future<Usuario> entrar({required String email, required String clave}) async {
    entradas.add('$email:$clave');
    if (clave != claveBuena) _rechazar();
    return usuarioDePrueba();
  }

  @override
  Future<void> verificarClave({
    required String email,
    required String clave,
  }) async {
    verificaciones.add('$email:$clave');
    if (clave != claveBuena) _rechazar();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late AutenticadorFalso lector;
  late AlmacenEnMemoria almacen;
  late ServicioHuella huella;

  setUp(() {
    lector = AutenticadorFalso();
    almacen = AlmacenEnMemoria();
    huella = ServicioHuella(autenticador: lector, almacen: almacen);
  });

  Future<void> dejarActiva(String correo, {String clave = _clave}) =>
      huella.activar(email: correo, clave: clave, verificar: (_, _) async {});

  final botonHuella = find.widgetWithText(
    CupoSecondaryButton,
    'Entrar con huella',
  );

  group('Iniciar sesión', () {
    Future<void> montar(
      WidgetTester tester,
      _RepoFalso repo, {
      ServicioHuella? servicio,
    }) async {
      await montarPantalla(
        tester,
        Scaffold(
          body: SignInForm(onVolver: () {}, onCrearCuenta: () {}),
        ),
        repositorio: repo,
        huella: servicio,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sin huella activa no ofrece entrar con huella', (
      tester,
    ) async {
      await montar(tester, _RepoFalso(), servicio: huella);

      expect(botonHuella, findsNothing);
      expect(find.widgetWithText(CupoPrimaryButton, 'Entrar'), findsOneWidget);
    });

    testWidgets('sin servicio de huella (la web) no la ofrece', (tester) async {
      await dejarActiva(_correo);
      await montar(tester, _RepoFalso());

      expect(botonHuella, findsNothing);
    });

    testWidgets('sin lector en el teléfono no la ofrece', (tester) async {
      await dejarActiva(_correo);
      lector.hayLector = false;
      await montar(tester, _RepoFalso(), servicio: huella);

      expect(botonHuella, findsNothing);
    });

    testWidgets('con huella activa la ofrece, con el correo a la vista, y '
        'entra con lo guardado', (tester) async {
      await dejarActiva(_correo);
      final repo = _RepoFalso();
      await montar(tester, repo, servicio: huella);

      expect(botonHuella, findsOneWidget);
      expect(find.text('Como $_correo'), findsOneWidget);

      await tester.tap(botonHuella);
      await tester.pumpAndSettle();

      expect(lector.pedidos, [ServicioHuella.motivoEntrar]);
      expect(repo.entradas, ['$_correo:$_clave']);
      expect(find.byType(CupoErrorBanner), findsNothing);
    });

    testWidgets('si la clave cambió, lo dice y deja de ofrecer la huella', (
      tester,
    ) async {
      await dejarActiva(_correo, clave: 'clave-vieja');
      await montar(tester, _RepoFalso(), servicio: huella);

      await tester.tap(botonHuella);
      await tester.pumpAndSettle();

      expect(find.text(ServicioHuella.mensajeClaveCambio), findsOneWidget);
      expect(botonHuella, findsNothing);
      expect(almacen.datos, isEmpty);
    });

    testWidgets('cancelar no muestra ningún error', (tester) async {
      await dejarActiva(_correo);
      lector.respuesta = _cancelado;
      final repo = _RepoFalso();
      await montar(tester, repo, servicio: huella);

      await tester.tap(botonHuella);
      await tester.pumpAndSettle();

      expect(find.byType(CupoErrorBanner), findsNothing);
      expect(repo.entradas, isEmpty);
      expect(botonHuella, findsOneWidget);
    });
  });

  group('Tu cuenta', () {
    final opcion = find.widgetWithText(OpcionDeCuenta, 'Entrar con huella');
    final interruptor = find.descendant(
      of: opcion,
      matching: find.byType(Switch),
    );

    Future<void> abrirHoja(
      WidgetTester tester,
      _RepoFalso repo, {
      ServicioHuella? servicio,
    }) async {
      await montarPantalla(
        tester,
        const Scaffold(body: Center(child: BotonDeCuenta())),
        usuario: usuarioDePrueba(),
        repositorio: repo,
        huella: servicio,
      );
      await tester.tap(find.byType(BotonDeCuenta));
      await tester.pumpAndSettle();
    }

    bool encendido(WidgetTester tester) =>
        tester.widget<Switch>(interruptor).value;

    testWidgets('sin lector no aparece la opción', (tester) async {
      lector.hayLector = false;
      await abrirHoja(tester, _RepoFalso(), servicio: huella);

      expect(find.text('Tu cuenta'), findsOneWidget);
      expect(opcion, findsNothing);
    });

    testWidgets('sin servicio de huella (la web) no aparece la opción', (
      tester,
    ) async {
      await abrirHoja(tester, _RepoFalso());

      expect(opcion, findsNothing);
    });

    testWidgets('encender pide la huella y la clave, y la guarda', (
      tester,
    ) async {
      final repo = _RepoFalso();
      await abrirHoja(tester, repo, servicio: huella);

      expect(opcion, findsOneWidget);
      expect(encendido(tester), isFalse);

      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(lector.pedidos, [ServicioHuella.motivoActivar]);
      expect(find.text('Confirma tu clave'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        _clave,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Activar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirma tu clave'), findsNothing);
      expect(repo.verificaciones, ['$_correo:$_clave']);
      expect(encendido(tester), isTrue);
      expect(await huella.activaPara(_correo), isTrue);
    });

    testWidgets('con la clave equivocada lo dice y no guarda nada', (
      tester,
    ) async {
      await abrirHoja(tester, _RepoFalso(), servicio: huella);

      await tester.tap(interruptor);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'otra-clave',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Activar'));
      await tester.pumpAndSettle();

      expect(find.text(ServicioHuella.mensajeClaveEquivocada), findsOneWidget);
      expect(almacen.datos, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(encendido(tester), isFalse);
    });

    testWidgets('si se cancela la huella, no pide la clave', (tester) async {
      lector.respuesta = _cancelado;
      await abrirHoja(tester, _RepoFalso(), servicio: huella);

      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(find.text('Confirma tu clave'), findsNothing);
      expect(find.byType(CupoErrorBanner), findsNothing);
      expect(encendido(tester), isFalse);
    });

    testWidgets('apagar borra lo guardado sin pedir la huella', (tester) async {
      await dejarActiva(_correo);
      await abrirHoja(tester, _RepoFalso(), servicio: huella);

      expect(encendido(tester), isTrue);

      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(encendido(tester), isFalse);
      expect(almacen.datos, isEmpty);
      expect(lector.pedidos, isEmpty);
    });

    testWidgets('la huella de otra cuenta sale apagada', (tester) async {
      await dejarActiva('andres@ejemplo.com');
      await abrirHoja(tester, _RepoFalso(), servicio: huella);

      expect(encendido(tester), isFalse);
    });
  });
}

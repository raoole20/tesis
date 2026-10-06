import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/auth/presentation/destino_pantalla.dart';
import 'package:cupo/features/auth/presentation/estado/estado_screens.dart';
import 'package:cupo/features/auth/presentation/sign_in_screen.dart';
import 'package:cupo/features/auth/presentation/sign_up_screen.dart';
import 'package:cupo/features/auth/presentation/welcome_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'soporte/banco_de_pruebas.dart';

/// Pruebas de las pantallas del primer ingreso y de las de estado de cuenta.
///
/// Se montan sueltas, no dentro de `main()`: la app real llama a
/// `Supabase.initialize`, y una prueba de widget no debe pedir credenciales
/// ni red. El armazón está en `soporte/banco_de_pruebas.dart`.
void main() {
  setUpAll(() {
    // Sin esto, google_fonts intenta descargar Manrope durante la prueba.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('L1 — Bienvenida', () {
    testWidgets('muestra la marca, los dos caminos y el aviso legal', (
      tester,
    ) async {
      await montarPantalla(tester, const WelcomeScreen());

      expect(find.text('Cupo'), findsOneWidget);
      expect(find.byType(CupoLogoMark), findsOneWidget);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Crear cuenta con mi correo'), findsOneWidget);
      expect(
        find.textContaining('no afiliado a la universidad'),
        findsOneWidget,
      );
    });

    testWidgets('«Crear cuenta con mi correo» lleva al registro', (
      tester,
    ) async {
      await montarPantalla(tester, const WelcomeScreen());

      await tester.tap(find.text('Crear cuenta con mi correo'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });

    testWidgets('«Iniciar sesión» lleva al login', (tester) async {
      await montarPantalla(tester, const WelcomeScreen());

      final inlineLink =
          tester.widget<CupoInlineLinkText>(find.byType(CupoInlineLinkText));
      inlineLink.onTap();
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Bienvenida de vuelta'), findsOneWidget);
    });
  });

  group('L2 — Crear cuenta', () {
    testWidgets('pide rol, nombre, correo, cédula, teléfono y clave', (
      tester,
    ) async {
      await montarPantalla(tester, const SignUpScreen());

      expect(find.text('¿Cómo vas a usar Cupo?'), findsOneWidget);
      expect(find.text('Soy estudiante'), findsOneWidget);
      expect(find.text('Soy conductor'), findsOneWidget);
      expect(find.text('Nombre y apellido'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Cédula'), findsOneWidget);
      expect(find.text('Teléfono (el de WhatsApp)'), findsOneWidget);
      expect(find.text('Clave'), findsOneWidget);
    });

    testWidgets('el rol se puede cambiar y arranca en estudiante', (
      tester,
    ) async {
      await montarPantalla(tester, const SignUpScreen());

      CupoChoiceTile tejaDe(String titulo) => tester.widget<CupoChoiceTile>(
        find.ancestor(
          of: find.text(titulo),
          matching: find.byType(CupoChoiceTile),
        ),
      );

      expect(tejaDe('Soy estudiante').seleccionado, isTrue);
      expect(tejaDe('Soy conductor').seleccionado, isFalse);

      await tester.tap(find.text('Soy conductor'));
      await tester.pump();

      expect(tejaDe('Soy estudiante').seleccionado, isFalse);
      expect(tejaDe('Soy conductor').seleccionado, isTrue);
    });

    testWidgets('no envía nada con el formulario vacío: avisa qué falta', (
      tester,
    ) async {
      await montarPantalla(tester, const SignUpScreen());

      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pump();

      // Si hubiera llegado a Supabase, la prueba reventaría por falta de
      // inicialización. Que aparezca el aviso demuestra que ni lo intentó.
      expect(find.byType(CupoErrorBanner), findsOneWidget);
      expect(find.text('Escribe tu nombre y apellido.'), findsOneWidget);
    });

    testWidgets('«Ver» descubre la clave y cambia a «Ocultar»', (tester) async {
      await montarPantalla(tester, const SignUpScreen());

      expect(find.text('Ver'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver'));
      await tester.pump();

      expect(find.text('Ocultar'), findsOneWidget);
      expect(find.text('Ver'), findsNothing);
    });
  });

  group('L4 — Iniciar sesión', () {
    testWidgets('ofrece Google, correo y clave, y la salida al registro', (
      tester,
    ) async {
      await montarPantalla(tester, const SignInScreen());

      expect(find.text('Entrar con Google'), findsOneWidget);
      expect(find.text('o con tu correo'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Olvidé mi clave'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.textContaining('¿No tienes cuenta?'), findsOneWidget);
    });

    testWidgets('un correo sin arroba no llega al backend', (tester) async {
      await montarPantalla(tester, const SignInScreen());

      await tester.enterText(find.byType(TextField).first, 'genesis');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Escribe un correo válido.'), findsOneWidget);
    });
  });

  group('Pantallas de estado de cuenta', () {
    testWidgets('pendiente: dice que está en revisión y no ofrece reenviar', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const EnRevisionScreen(),
        usuario: usuarioDePrueba(estado: EstadoCuenta.pendiente),
      );

      expect(find.text('Tu registro está en revisión'), findsOneWidget);
      expect(find.textContaining('genesis@ejemplo.com'), findsOneWidget);
      expect(find.text('Volver a enviar'), findsNothing);
    });

    testWidgets('rechazada: muestra el motivo y deja reenviar', (tester) async {
      await montarPantalla(
        tester,
        const RechazadaScreen(),
        usuario: usuarioDePrueba(
          estado: EstadoCuenta.rechazada,
          motivoRechazo: 'La foto de la licencia está borrosa.',
        ),
      );

      expect(find.text('Tu registro necesita correcciones'), findsOneWidget);
      expect(
        find.text('La foto de la licencia está borrosa.'),
        findsOneWidget,
      );
      expect(find.text('Volver a enviar'), findsOneWidget);
    });

    testWidgets('rechazada sin motivo: no deja el bloque vacío', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const RechazadaScreen(),
        usuario: usuarioDePrueba(estado: EstadoCuenta.rechazada),
      );

      expect(
        find.text('El administrador no dejó un motivo.'),
        findsOneWidget,
      );
    });

    testWidgets('suspendida: explica y da por dónde reclamar', (tester) async {
      await montarPantalla(
        tester,
        const SuspendidaScreen(),
        usuario: usuarioDePrueba(estado: EstadoCuenta.suspendida),
      );

      expect(find.text('Tu cuenta está deshabilitada'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  group('Marcadores de las pantallas que faltan', () {
    testWidgets('el conductor aprobado sin onboarding ve su próximo paso', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const EnConstruccionScreen(
          titulo: 'Elige tus zonas de trabajo',
          paso: 'Selección de zonas con vista previa en mapa',
        ),
        usuario: usuarioDePrueba(
          rol: RolUsuario.conductor,
          estado: EstadoCuenta.aprobada,
        ),
      );

      expect(find.text('Elige tus zonas de trabajo'), findsOneWidget);
      expect(find.textContaining('rol: conductor'), findsOneWidget);
      expect(find.textContaining('estado: aprobada'), findsOneWidget);
    });
  });
}

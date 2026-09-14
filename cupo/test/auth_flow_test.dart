import 'package:cupo/features/auth/presentation/sign_in_screen.dart';
import 'package:cupo/features/auth/presentation/sign_up_screen.dart';
import 'package:cupo/features/auth/presentation/verify_phone_screen.dart';
import 'package:cupo/main.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pruebas de las cuatro pantallas del primer ingreso (L1–L4).
///
/// Se monta la app completa en el lienzo del diseño (390×844) para que las
/// medidas de `CupoScreen` se ejerciten tal como se verán en el teléfono.
void main() {
  setUpAll(() {
    // Sin esto, google_fonts intenta descargar Manrope durante la prueba.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MainApp());
  }

  group('L1 — Bienvenida', () {
    testWidgets('muestra la marca, los dos caminos y el aviso legal',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Cupo'), findsOneWidget);
      expect(find.byType(CupoLogoMark), findsOneWidget);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Crear cuenta con mi teléfono'), findsOneWidget);
      expect(
        find.textContaining('no afiliado a la universidad'),
        findsOneWidget,
      );
    });

    testWidgets('«Crear cuenta con mi teléfono» lleva al registro',
        (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Crear cuenta con mi teléfono'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });

    testWidgets('«Iniciar sesión» lleva al login', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Bienvenida de vuelta'), findsOneWidget);
    });
  });

  group('L2 — Crear cuenta', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Crear cuenta con mi teléfono'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide nombre, cédula, teléfono y clave', (tester) async {
      await openSignUp(tester);

      expect(find.text('Nombre y apellido'), findsOneWidget);
      expect(find.text('Cédula'), findsOneWidget);
      expect(find.text('Teléfono (el de WhatsApp)'), findsOneWidget);
      expect(find.text('Clave'), findsOneWidget);
      expect(
        find.text('Te mandamos un código por WhatsApp para verificarlo.'),
        findsOneWidget,
      );
    });

    testWidgets('«Ver» descubre la clave y cambia a «Ocultar»',
        (tester) async {
      await openSignUp(tester);

      expect(find.text('Ver'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver'));
      await tester.pump();

      expect(find.text('Ocultar'), findsOneWidget);
      expect(find.text('Ver'), findsNothing);
    });
  });

  group('L3 — Verificar teléfono', () {
    testWidgets('«Verificar» se habilita solo con el código completo',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(VerifyPhoneScreen), findsOneWidget);
      expect(find.byType(CupoOtpBox), findsNWidgets(6));

      var boton = tester.widget<CupoPrimaryButton>(
        find.byType(CupoPrimaryButton),
      );
      expect(boton.onPressed, isNull, reason: 'sin código no se puede seguir');

      await tester.enterText(find.byType(TextField), '472913');
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      boton = tester.widget<CupoPrimaryButton>(
        find.byType(CupoPrimaryButton),
      );
      expect(boton.onPressed, isNotNull);

      // Suelta el temporizador del contador y la animación del cursor.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('L4 — Iniciar sesión', () {
    testWidgets('ofrece Google, teléfono y clave, y la salida al registro',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Entrar con Google'), findsOneWidget);
      expect(find.text('o con tu teléfono'), findsOneWidget);
      expect(find.text('Teléfono'), findsOneWidget);
      expect(find.text('Olvidé mi clave'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.textContaining('¿No tienes cuenta?'), findsOneWidget);
    });
  });
}

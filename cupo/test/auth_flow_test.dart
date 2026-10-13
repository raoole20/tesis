import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/auth/presentation/destino_pantalla.dart';
import 'package:cupo/features/auth/presentation/estado/estado_screens.dart';
import 'package:cupo/features/auth/presentation/sign_in_form.dart';
import 'package:cupo/features/auth/presentation/sign_up_form.dart';
import 'package:cupo/features/auth/presentation/sign_up_role_form.dart';
import 'package:cupo/features/auth/presentation/verify_phone_screen.dart';
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
      expect(find.byType(CupoHero), findsOneWidget);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsOneWidget);
      expect(
        find.widgetWithText(CupoPrimaryButton, 'Iniciar sesión'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CupoSecondaryButton, 'Crear cuenta'),
        findsOneWidget,
      );
      expect(find.text('Explorar como invitado'), findsOneWidget);
      expect(
        find.textContaining('no afiliado a la universidad'),
        findsOneWidget,
      );
    });

    testWidgets('no ofrece entrar con Google', (tester) async {
      await montarPantalla(tester, const WelcomeScreen());
      expect(find.textContaining('Google'), findsNothing);

      await tester.tap(
        find.widgetWithText(CupoSecondaryButton, 'Crear cuenta'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Google'), findsNothing);
    });

    testWidgets(
      '«Crear cuenta» despliega la elección de rol en la misma pantalla',
      (tester) async {
        await montarPantalla(tester, const WelcomeScreen());

        await tester.tap(
          find.widgetWithText(CupoSecondaryButton, 'Crear cuenta'),
        );
        await tester.pumpAndSettle();

        // Sigue siendo la misma ruta: la hoja creció, no se empujó nada.
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.byType(SignUpRoleForm), findsOneWidget);
        expect(find.byType(SignUpForm), findsNothing);
        expect(find.text('¿Cómo vas a usar Cupo?'), findsOneWidget);
        expect(find.text('Explorar como invitado'), findsNothing);
        expect(find.text('Tu puesto fijo hasta la URBE'), findsNothing);
      },
    );

    testWidgets('«Iniciar sesión» despliega el login en la misma pantalla', (
      tester,
    ) async {
      await montarPantalla(tester, const WelcomeScreen());

      await tester.tap(
        find.widgetWithText(CupoPrimaryButton, 'Iniciar sesión'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInForm), findsOneWidget);
      expect(find.text('Qué bueno verte'), findsOneWidget);
    });

    testWidgets('el retroceso pliega la hoja y vuelve a los dos caminos', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.iniciarSesion),
      );

      await tester.tap(find.byType(CupoBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SignInForm), findsNothing);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsOneWidget);
    });

    testWidgets('el «atrás» del sistema también pliega la hoja', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.elegirRol),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SignUpRoleForm), findsNothing);
      expect(
        find.widgetWithText(CupoPrimaryButton, 'Iniciar sesión'),
        findsOneWidget,
      );
    });

    testWidgets('«Créala» cambia al registro sin plegar la hoja', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.iniciarSesion),
      );

      await tester.tapOnText(find.textRange.ofSubstring('Créala'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpRoleForm), findsOneWidget);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsNothing);
    });
  });

  group('L2 — Crear cuenta, paso 1: rol', () {
    CupoChoiceTile tejaDe(WidgetTester tester, String titulo) =>
        tester.widget<CupoChoiceTile>(
          find.ancestor(
            of: find.text(titulo),
            matching: find.byType(CupoChoiceTile),
          ),
        );

    CupoPrimaryButton continuar(WidgetTester tester) =>
        tester.widget(find.widgetWithText(CupoPrimaryButton, 'Continuar'));

    testWidgets('muestra solo las dos opciones, sin campos', (tester) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.elegirRol),
      );

      expect(
        find.bySemanticsLabel('Paso 1 de 2: Tipo de cuenta'),
        findsOneWidget,
      );
      expect(find.textContaining('Elige bien'), findsNothing);

      // Las dos opciones son cuadrados perfectos y del mismo tamaño.
      for (final titulo in ['Soy estudiante', 'Soy conductor']) {
        final lado = tester.getSize(
          find.descendant(
            of: find.ancestor(
              of: find.text(titulo),
              matching: find.byType(CupoChoiceTile),
            ),
            matching: find.byType(AspectRatio),
          ),
        );
        expect(lado.width, lado.height);
      }
      expect(find.text('Soy estudiante'), findsOneWidget);
      expect(find.text('Soy conductor'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('no marca ningún rol ni deja seguir hasta elegir uno', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.elegirRol),
      );

      expect(tejaDe(tester, 'Soy estudiante').seleccionado, isFalse);
      expect(tejaDe(tester, 'Soy conductor').seleccionado, isFalse);
      expect(continuar(tester).onPressed, isNull);

      await tester.tap(find.text('Soy conductor'));
      await tester.pump();

      expect(tejaDe(tester, 'Soy conductor').seleccionado, isTrue);
      expect(continuar(tester).onPressed, isNotNull);
    });

    testWidgets('«Continuar» abre el formulario del rol elegido', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.elegirRol),
      );

      await tester.tap(find.text('Soy conductor'));
      await tester.pump();
      final boton = find.widgetWithText(CupoPrimaryButton, 'Continuar');
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.byType(SignUpRoleForm), findsNothing);
      expect(
        tester.widget<SignUpForm>(find.byType(SignUpForm)).rol,
        RolUsuario.conductor,
      );
      expect(find.bySemanticsLabel('Paso 2 de 2: Tus datos'), findsOneWidget);
      expect(find.text('Tu cuenta de conductor'), findsOneWidget);
    });

    testWidgets('volver del paso 2 regresa al paso 1 con el rol marcado', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.conductor,
        ),
      );

      await tester.tap(find.byType(CupoBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpRoleForm), findsOneWidget);
      expect(tejaDe(tester, 'Soy conductor').seleccionado, isTrue);
    });

    testWidgets('el «atrás» del sistema en el paso 2 vuelve al paso 1', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.estudiante,
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SignUpForm), findsNothing);
      expect(find.byType(SignUpRoleForm), findsOneWidget);
      expect(find.text('Tu puesto fijo hasta la URBE'), findsNothing);
    });
  });

  group('L2 — Crear cuenta, paso 2: datos', () {
    testWidgets('pide nombre, correo, cédula, teléfono y clave, sin el rol', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.estudiante,
        ),
      );

      expect(find.text('Tu cuenta de estudiante'), findsOneWidget);
      expect(find.byType(CupoChoiceTile), findsNothing);
      expect(find.text('Nombre y apellido'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Cédula'), findsOneWidget);
      expect(find.text('Teléfono (el de WhatsApp)'), findsOneWidget);
      expect(find.text('Clave'), findsOneWidget);
      expect(find.text('Por ahí te contacta el conductor.'), findsOneWidget);
    });

    testWidgets('al conductor le habla de la revisión y la licencia', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.conductor,
        ),
      );

      expect(find.textContaining('licencia'), findsOneWidget);
      expect(find.text('Por ahí te escriben los estudiantes.'), findsOneWidget);
      // El conductor puede registrarse con cédula o con el RIF de su empresa.
      expect(find.text('Cédula o RIF'), findsOneWidget);
      expect(find.textContaining('dan crédito'), findsNothing);
    });

    testWidgets('no envía nada con el formulario vacío: avisa qué falta', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.estudiante,
        ),
      );

      // «Crear cuenta» también es el nombre del paso en el encabezado: se
      // busca el botón, no el texto.
      final boton = find.widgetWithText(CupoPrimaryButton, 'Crear cuenta');
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await tester.pump();

      // Si hubiera llegado a Supabase, la prueba reventaría por falta de
      // inicialización. Que aparezca el aviso demuestra que ni lo intentó.
      expect(find.byType(CupoErrorBanner), findsOneWidget);
      expect(find.text('Escribe tu nombre y apellido.'), findsOneWidget);
    });

    testWidgets('el ojo descubre la clave y vuelve a ocultarla', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(
          modoInicial: ModoAcceso.crearCuenta,
          rolInicial: RolUsuario.estudiante,
        ),
      );

      final ver = find.byIcon(Icons.visibility_outlined);
      expect(ver, findsOneWidget);
      expect(find.bySemanticsLabel('Mostrar la clave'), findsOneWidget);
      await tester.ensureVisible(ver);
      await tester.pumpAndSettle();

      await tester.tap(ver);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.bySemanticsLabel('Ocultar la clave'), findsOneWidget);
      expect(ver, findsNothing);
    });
  });

  group('L3 — Código', () {
    testWidgets('enmascara el número y no deja seguir sin los seis dígitos', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const VerifyPhoneScreen(phoneNumber: '0414 555 0193'),
      );

      expect(
        find.text('Escribe el código que te llegó al ••• 0193'),
        findsOneWidget,
      );
      expect(find.byType(CupoOtpBox), findsNWidgets(6));

      CupoPrimaryButton continuar() =>
          tester.widget(find.widgetWithText(CupoPrimaryButton, 'Continuar'));

      expect(continuar().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '472');
      await tester.pump();
      expect(continuar().onPressed, isNull);

      await tester.enterText(find.byType(TextField), '472910');
      await tester.pump();
      expect(continuar().onPressed, isNotNull);
    });
  });

  group('L4 — Iniciar sesión', () {
    testWidgets('ofrece correo y clave y la salida al registro', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.iniciarSesion),
      );

      expect(find.text('Qué bueno verte'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('¿La olvidaste?'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.textContaining('¿No tienes cuenta?'), findsOneWidget);
    });

    testWidgets('un correo sin arroba no llega al backend', (tester) async {
      await montarPantalla(
        tester,
        const WelcomeScreen(modoInicial: ModoAcceso.iniciarSesion),
      );

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
      expect(find.text('La foto de la licencia está borrosa.'), findsOneWidget);
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

      expect(find.text('El administrador no dejó un motivo.'), findsOneWidget);
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
    testWidgets('el administrador aprobado ve su próximo paso', (tester) async {
      await montarPantalla(
        tester,
        const EnConstruccionScreen(
          titulo: 'Bandeja de solicitudes',
          paso: 'Aprobar y rechazar registros',
        ),
        usuario: usuarioDePrueba(
          rol: RolUsuario.administrador,
          estado: EstadoCuenta.aprobada,
        ),
      );

      expect(find.text('Bandeja de solicitudes'), findsOneWidget);
      expect(find.textContaining('rol: administrador'), findsOneWidget);
      expect(find.textContaining('estado: aprobada'), findsOneWidget);
    });
  });
}

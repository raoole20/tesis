import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/onboarding/presentation/mapa_domicilio.dart';
import 'package:cupo/features/profile/presentation/perfil_estudiante_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../soporte/banco_de_pruebas.dart';

/// Pruebas de «Completa tu perfil de estudiante», que todavía no habla con la
/// base: se recorre de punta a punta sin Supabase.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Dentro de la zona provisional «5 de Julio».
  const pinCincoDeJulio = LatLng(10.655, -71.600);

  Future<void> montar(WidgetTester tester, {LatLng? pinInicial}) {
    return montarPantalla(
      tester,
      PerfilEstudianteScreen(pinInicial: pinInicial),
      usuario: usuarioDePrueba(estado: EstadoCuenta.perfilIncompleto),
    );
  }

  Future<void> tocarBoton(WidgetTester tester, String rotulo) async {
    final boton = find.widgetWithText(CupoPrimaryButton, rotulo);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  Future<void> llenarEstudios(WidgetTester tester) async {
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(1), 'Ingeniería en Computación');
    await tester.enterText(campos.at(2), '20231234');
    await tocarBoton(tester, 'Continuar');
  }

  group('Paso 1: estudios', () {
    testWidgets('pide universidad, carrera y carnet, con la URBE precargada', (
      tester,
    ) async {
      await montar(tester);

      expect(
        find.bySemanticsLabel('Paso 1 de 2: Tus estudios'),
        findsOneWidget,
      );
      expect(find.text('Universidad'), findsOneWidget);
      expect(find.text('Carrera'), findsOneWidget);
      expect(find.text('Número de carnet'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'URBE',
      );
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('no avanza sin carrera: avisa qué falta', (tester) async {
      await montar(tester);

      await tocarBoton(tester, 'Continuar');

      expect(find.text('Escribe tu carrera.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });
  });

  group('Paso 2: casa en el mapa', () {
    testWidgets('muestra el mapa y no deja enviar sin la casa marcada', (
      tester,
    ) async {
      await montar(tester);
      await llenarEstudios(tester);

      expect(find.bySemanticsLabel('Paso 2 de 2: Tu casa'), findsOneWidget);
      expect(find.byType(MapaDomicilio), findsOneWidget);
      expect(find.bySemanticsLabel('Usar mi ubicación'), findsOneWidget);
      expect(find.text('Todavía no marcas tu casa.'), findsOneWidget);
      expect(
        tester
            .widget<CupoPrimaryButton>(
              find.widgetWithText(CupoPrimaryButton, 'Enviar a revisión'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('al marcar la casa muestra la zona y habilita el envío', (
      tester,
    ) async {
      await montar(tester);
      await llenarEstudios(tester);

      // El toque sobre las teselas no es fiable en una prueba: se simula lo
      // que haría el mapa al recibirlo.
      tester
          .widget<MapaDomicilio>(find.byType(MapaDomicilio))
          .onPin(pinCincoDeJulio);
      await tester.pumpAndSettle();

      expect(find.text('Zona: 5 de Julio'), findsOneWidget);
      expect(find.text('Punto de referencia (opcional)'), findsOneWidget);
      expect(
        tester
            .widget<CupoPrimaryButton>(
              find.widgetWithText(CupoPrimaryButton, 'Enviar a revisión'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('fuera de las zonas avisa en warning, pero deja enviar', (
      tester,
    ) async {
      await montar(tester, pinInicial: const LatLng(10.0, -70.0));
      await llenarEstudios(tester);

      expect(
        find.text('Fuera de las zonas de cobertura por ahora.'),
        findsOneWidget,
      );
    });

    testWidgets('volver regresa a los estudios sin perder lo escrito', (
      tester,
    ) async {
      await montar(tester);
      await llenarEstudios(tester);

      await tester.tap(find.byType(CupoBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        'Ingeniería en Computación',
      );
    });
  });

  testWidgets('al enviar muestra el resumen de lo que iría a revisión', (
    tester,
  ) async {
    await montar(tester, pinInicial: pinCincoDeJulio);
    await llenarEstudios(tester);

    await tester.enterText(find.byType(TextField), 'Casa azul');
    await tocarBoton(tester, 'Enviar a revisión');

    expect(find.text('Tu perfil está listo'), findsOneWidget);
    expect(find.text('URBE'), findsOneWidget);
    expect(find.text('Ingeniería en Computación'), findsOneWidget);
    expect(find.text('20231234'), findsOneWidget);
    expect(find.text('5 de Julio · Casa azul'), findsOneWidget);
  });
}

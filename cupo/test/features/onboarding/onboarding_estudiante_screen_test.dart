import 'package:cupo/features/onboarding/presentation/onboarding_estudiante_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../soporte/banco_de_pruebas.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('OnboardingEstudianteScreen', () {
    testWidgets('renderiza mapa, título, FAB y estado inicial sin pin', (
      tester,
    ) async {
      await montarPantalla(
        tester,
        const OnboardingEstudianteScreen(),
        usuario: usuarioDePrueba(onboardingCompleto: false),
      );

      // Título en el AppBar
      expect(find.text('Marca dónde vives'), findsOneWidget);

      // Mapa interactivo
      expect(find.byType(FlutterMap), findsOneWidget);

      // Botón de ubicación GPS
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // Panel inferior
      expect(find.text('Tu Domicilio'), findsOneWidget);
      expect(
        find.text(
          'Toca el mapa para colocar el pin donde vives o usa tu ubicación actual.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confirmar mi domicilio'), findsOneWidget);

      // En estado inicial sin pin, el botón está deshabilitado (onPressed es null)
      final boton = tester.widget<CupoPrimaryButton>(
        find.byType(CupoPrimaryButton),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('con pinInicial se muestra la zona detectada y se habilita la confirmación', (
      tester,
    ) async {
      // Coordenada dentro de '5 de Julio': 10.655, -71.600
      const pinCincoDeJulio = LatLng(10.655, -71.600);

      await montarPantalla(
        tester,
        const OnboardingEstudianteScreen(pinInicial: pinCincoDeJulio),
        usuario: usuarioDePrueba(onboardingCompleto: false),
      );

      // Debe aparecer el chip con la zona detectada
      expect(find.textContaining('5 de Julio'), findsOneWidget);

      // Debe aparecer el campo opcional de referencia / sector
      expect(find.byType(CupoTextInput), findsOneWidget);

      // El botón ahora debe estar habilitado
      final boton = tester.widget<CupoPrimaryButton>(
        find.byType(CupoPrimaryButton),
      );
      expect(boton.onPressed, isNotNull);
    });
  });
}

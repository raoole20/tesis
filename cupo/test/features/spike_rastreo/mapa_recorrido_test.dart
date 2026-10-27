import 'dart:math';

import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/traza.dart';
import 'package:cupo/features/spike_rastreo/presentation/mapa_recorrido.dart';
import 'package:cupo/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

/// El ángulo de un `Transform.rotate`, en radianes.
double _angulo(WidgetTester tester, Key key) {
  final m = tester.widget<Transform>(find.byKey(key)).transform;
  return atan2(m.entry(1, 0), m.entry(0, 0));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('BrujulaMapa', () {
    Future<MapController> montar(WidgetTester tester) async {
      final controlador = MapController();
      addTearDown(controlador.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FlutterMap(
              mapController: controlador,
              options: const MapOptions(
                initialCenter: LatLng(10.7, -71.6),
                initialZoom: 14,
              ),
              children: const [
                Align(alignment: Alignment.topRight, child: BrujulaMapa()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      return controlador;
    }

    const flecha = ValueKey('brujula-flecha');

    testWidgets('gira con el mapa', (tester) async {
      final controlador = await montar(tester);
      expect(_angulo(tester, flecha), closeTo(0, 1e-9));

      controlador.rotate(90);
      await tester.pump();
      expect(_angulo(tester, flecha), closeTo(pi / 2, 1e-6));

      controlador.rotate(-45);
      await tester.pump();
      expect(_angulo(tester, flecha), closeTo(-pi / 4, 1e-6));
    });

    testWidgets('al tocarla el mapa vuelve al norte', (tester) async {
      final controlador = await montar(tester);
      controlador.rotate(135);
      await tester.pump();

      await tester.tap(find.byTooltip('Volver al norte'));
      await tester.pump();

      expect(controlador.camera.rotation, 0);
      expect(_angulo(tester, flecha), closeTo(0, 1e-9));
    });
  });

  testWidgets('el mapa del resultado dibuja ruta, traza, brecha, flechas y '
      'puntos', (tester) async {
    final t0 = DateTime.utc(2026, 10, 27, 13);
    PuntoTraza p(int seq, int s, double m) => PuntoTraza(
      seq: seq,
      punto: PuntoGeo(10.7 + m / 111195, -71.6),
      capturadaEn: t0.add(Duration(seconds: s)),
      estadoApp: EstadoApp.paused,
    );
    final tramos = tramosDeTraza([
      for (var i = 0; i < 10; i++) p(i + 1, i * 5, i * 60.0),
      p(11, 120, 700), // brecha de 75 s
      p(12, 125, 760),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MapaRecorrido(
            rutaPlanificada: const [
              PuntoGeo(10.7, -71.6),
              PuntoGeo(10.71, -71.6),
            ],
            tramos: tramos,
            inicio: const PuntoGeo(10.7, -71.6),
            llegada: const PuntoGeo(10.71, -71.6),
            domicilio: const PuntoGeo(10.705, -71.6),
            radioAvisoM: 1500,
            flechas: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final lineas = tester
        .widget<PolylineLayer>(find.byType(PolylineLayer))
        .polylines;
    // Ruta planificada + traza + brecha + traza.
    expect(lineas, hasLength(4));
    expect(lineas.where((l) => l.color == AppColors.danger), hasLength(1));
    expect(find.byType(CircleLayer), findsOneWidget);
    expect(find.byTooltip('Inicio'), findsOneWidget);
    expect(find.byTooltip('Llegada'), findsOneWidget);
    expect(find.byTooltip('Domicilio de prueba'), findsOneWidget);
    expect(find.byType(BrujulaMapa), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('en vivo, la unidad es una flecha orientada por su rumbo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: MapaRecorrido(
            trazaEnVivo: [PuntoGeo(10.7, -71.6), PuntoGeo(10.7, -71.599)],
            unidad: PuntoGeo(10.7, -71.599),
            rumboUnidad: 90,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Tu unidad'), findsOneWidget);
    expect(
      _angulo(tester, const ValueKey('unidad-flecha')),
      closeTo(pi / 2, 1e-6),
    );
  });
}

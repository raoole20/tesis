import 'package:cupo/features/onboarding/presentation/map_spike_screen.dart';
import 'package:cupo/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('MapSpikeScreen renderiza AppBar, FlutterMap, FAB y panel informativo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MapSpikeScreen(),
      ),
    );

    // Verificar AppBar con título
    expect(find.text('Ubicación de domicilio'), findsOneWidget);

    // Verificar presencia del mapa
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verificar botón flotante "Mi ubicación"
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);

    // Verificar panel inferior con estado inicial
    expect(find.text('Domicilio'), findsOneWidget);
    expect(
      find.text('Toca el mapa para colocar tu pin de domicilio'),
      findsOneWidget,
    );
  });
}

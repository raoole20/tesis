import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cupo/main.dart';

void main() {
  setUpAll(() {
    // Sin esto, google_fonts intenta descargar Manrope durante la prueba.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('la app arranca y muestra su pantalla inicial', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Cupo'), findsOneWidget);
  });
}

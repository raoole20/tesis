import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cupo/main.dart';

void main() {
  testWidgets('la app arranca y muestra su pantalla inicial', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Cupo'), findsOneWidget);
  });
}

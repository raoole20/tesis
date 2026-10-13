import 'package:cupo/core/venezuela/documento_identidad.dart';
import 'package:cupo/core/venezuela/telefono_movil.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

/// Campo de cédula con su estado, como lo usa el formulario de registro.
class _Documento extends StatefulWidget {
  const _Documento({required this.controller, required this.tipos});

  final TextEditingController controller;
  final List<TipoDocumento> tipos;

  @override
  State<_Documento> createState() => _DocumentoState();
}

class _DocumentoState extends State<_Documento> {
  TipoDocumento tipo = TipoDocumento.v;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupoDocumentoInput(
        controller: widget.controller,
        tipo: tipo,
        tipos: widget.tipos,
        onTipoChanged: (t) => setState(() => tipo = t),
      ),
    );
  }
}

class _Telefono extends StatefulWidget {
  const _Telefono({required this.controller});

  final TextEditingController controller;

  @override
  State<_Telefono> createState() => _TelefonoState();
}

class _TelefonoState extends State<_Telefono> {
  OperadoraMovil? operadora;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupoTelefonoInput(
        controller: widget.controller,
        operadora: operadora,
        onOperadoraChanged: (o) => setState(() => operadora = o),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CupoDocumentoInput', () {
    testWidgets('con un solo tipo, la «V» es fija: no abre nada', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(
        tester,
        _Documento(controller: controller, tipos: const [TipoDocumento.v]),
      );

      expect(find.text('V'), findsOneWidget);
      await tester.tap(find.text('V'));
      await tester.pumpAndSettle();
      expect(find.text('Tipo de documento'), findsNothing);
    });

    testWidgets('formatea la cédula con puntos y no deja pasar letras', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(
        tester,
        _Documento(controller: controller, tipos: TipoDocumento.values),
      );

      await tester.enterText(find.byType(TextField), 'v30111222x9');
      expect(controller.text, '30.111.222');
    });

    testWidgets('se cambia a «J» desde la hoja y reformatea como RIF', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(
        tester,
        _Documento(controller: controller, tipos: TipoDocumento.values),
      );

      await tester.enterText(find.byType(TextField), '00006372');
      await tester.tap(find.text('V'));
      await tester.pumpAndSettle();

      expect(find.text('Tipo de documento'), findsOneWidget);
      await tester.tap(find.text('J · Jurídico'));
      await tester.pumpAndSettle();

      expect(find.text('J'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '000063729');
      expect(controller.text, '00006372-9');
    });
  });

  group('CupoTelefonoInput', () {
    testWidgets('sin operadora muestra «04XX» y la hoja trae las seis', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(tester, _Telefono(controller: controller));

      expect(find.text('04XX'), findsOneWidget);
      await tester.tap(find.text('04XX'));
      await tester.pumpAndSettle();

      for (final o in OperadoraMovil.values) {
        expect(find.text(o.codigo), findsOneWidget);
      }
      await tester.tap(find.text('0424'));
      await tester.pumpAndSettle();

      expect(find.text('04XX'), findsNothing);
      expect(find.text('0424'), findsOneWidget);
    });

    testWidgets('limita a 7 dígitos y los agrupa', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(tester, _Telefono(controller: controller));

      await tester.enterText(find.byType(TextField), '123456789');
      expect(controller.text, '123 4567');
    });

    testWidgets('al pegar el número entero elige la operadora sola', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await montarPantalla(tester, _Telefono(controller: controller));

      await tester.enterText(find.byType(TextField), '0416 765 4321');
      await tester.pump();

      expect(controller.text, '765 4321');
      expect(find.text('0416'), findsOneWidget);
    });
  });
}

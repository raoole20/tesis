import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/auth/presentation/cuenta/boton_de_cuenta.dart';
import 'package:cupo/features/driver/presentation/vehiculo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

/// «Tu vehículo» en la hoja de la cuenta: la puerta al CRUD del vehículo
/// desde cualquier pestaña del conductor.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> abrirHoja(WidgetTester tester, RolUsuario rol) async {
    await montarPantalla(
      tester,
      const Scaffold(body: Center(child: BotonDeCuenta())),
      usuario: usuarioDePrueba(rol: rol),
    );
    await tester.tap(find.byType(BotonDeCuenta));
    await tester.pumpAndSettle();
  }

  testWidgets('el conductor ve «Tu vehículo» y abre el formulario', (
    tester,
  ) async {
    await abrirHoja(tester, RolUsuario.conductor);

    expect(find.text('Tu vehículo'), findsOneWidget);
    await tester.tap(find.text('Tu vehículo'));
    await tester.pumpAndSettle();

    // Se cerró la hoja y quedó el formulario encima.
    expect(find.byType(VehiculoScreen), findsOneWidget);
    expect(find.text('Tu cuenta'), findsNothing);
  });

  testWidgets('el estudiante no ve «Tu vehículo»', (tester) async {
    await abrirHoja(tester, RolUsuario.estudiante);
    expect(find.text('Tu vehículo'), findsNothing);
  });
}

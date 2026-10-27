import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/auth/presentation/cuenta/boton_de_cuenta.dart';
import 'package:cupo/features/driver/data/conductor_repository.dart';
import 'package:cupo/features/driver/data/zonas_repository.dart';
import 'package:cupo/features/driver/domain/vehiculo.dart';
import 'package:cupo/features/driver/domain/zona.dart';
import 'package:cupo/features/driver/presentation/cuentas_conductor_view.dart';
import 'package:cupo/features/driver/presentation/inicio_conductor_screen.dart';
import 'package:cupo/features/driver/presentation/ruta_conductor_view.dart';
import 'package:cupo/features/driver/presentation/semana_conductor_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

class _ZonasFalsas extends ZonasRepository {
  @override
  Future<List<Zona>> catalogo() async => const [];

  @override
  Future<Set<String>> misZonas() async => {};
}

class _ConductorFalso extends ConductorRepository {
  @override
  Future<Vehiculo?> miVehiculo() async => null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> montar(WidgetTester tester) async {
    await montarPantalla(
      tester,
      InicioConductorScreen(
        repositorio: _ZonasFalsas(),
        conductor: _ConductorFalso(),
        hoy: DateTime(2026, 10, 12),
      ),
      usuario: usuarioDePrueba(rol: RolUsuario.conductor),
    );
    await tester.pump();
  }

  Future<void> irA(WidgetTester tester, String pestana) async {
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(pestana),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('«Semana» muestra los cinco días y el de hoy vuelve a «Hoy»', (
    tester,
  ) async {
    await montar(tester);
    await irA(tester, 'Semana');

    expect(find.byType(SemanaConductorView), findsOneWidget);
    expect(find.text('Tu semana'), findsOneWidget);
    expect(find.byType(BotonDeCuenta), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Viernes 16 oct'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SemanaConductorView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    await tester.ensureVisible(find.text('Lunes 12 oct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunes 12 oct'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Génesis'), findsOneWidget);
  });

  testWidgets('«Ruta» muestra el recorrido con sus paradas', (tester) async {
    await montar(tester);
    await irA(tester, 'Ruta');

    expect(find.byType(RutaConductorView), findsOneWidget);
    expect(find.text('Tu ruta'), findsOneWidget);
    expect(find.text('Paradas'), findsOneWidget);
    expect(find.byType(BotonDeCuenta), findsOneWidget);
  });

  testWidgets('«Cuentas» suma los saldos y «Marcar pagado» los mueve', (
    tester,
  ) async {
    await montar(tester);
    await irA(tester, 'Cuentas');

    expect(find.byType(CuentasConductorView), findsOneWidget);
    // Cuadra con el «Por cobrar» del turno de ejemplo.
    expect(find.text('\$38,50'), findsOneWidget);
    expect(find.textContaining('7 pasajeros con saldo'), findsOneWidget);

    await tester.tap(find.text('Marcar pagado').first);
    await tester.pump();

    expect(find.text('\$33,00'), findsOneWidget);
    expect(find.textContaining('6 pasajeros con saldo'), findsOneWidget);
  });

  testWidgets('«Ver cuentas» de la hoja de hoy abre la pestaña', (
    tester,
  ) async {
    await montar(tester);

    final enlace = find.text('Ver cuentas');
    await tester.scrollUntilVisible(enlace, 200);
    // A media pantalla, lejos de la acción fija del pie.
    await Scrollable.ensureVisible(tester.element(enlace), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(enlace.hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Tus cuentas'), findsOneWidget);
  });
}

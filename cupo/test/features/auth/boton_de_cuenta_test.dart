import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:cupo/features/auth/presentation/cuenta/boton_de_cuenta.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

/// No toca Supabase: solo cuenta las veces que se pidió salir.
class _RepoQueSale extends AuthRepository {
  _RepoQueSale({this.falla = false});

  final bool falla;
  int salidas = 0;

  @override
  Future<void> salir() async {
    salidas++;
    if (falla) throw Exception('sin red');
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> montar(WidgetTester tester, _RepoQueSale repo) async {
    await montarPantalla(
      tester,
      const Scaffold(body: Center(child: BotonDeCuenta())),
      usuario: usuarioDePrueba(),
      repositorio: repo,
    );
  }

  testWidgets('muestra las iniciales y abre la hoja de la cuenta', (
    tester,
  ) async {
    final repo = _RepoQueSale();
    await montar(tester, repo);

    expect(find.text('GM'), findsOneWidget);

    await tester.tap(find.byType(BotonDeCuenta));
    await tester.pumpAndSettle();

    expect(find.text('Tu cuenta'), findsOneWidget);
    expect(find.text('Génesis Materán'), findsOneWidget);
    expect(find.text('Estudiante · genesis@ejemplo.com'), findsOneWidget);
    expect(repo.salidas, 0);
  });

  testWidgets('«Cerrar sesión» pide salir al repositorio', (tester) async {
    final repo = _RepoQueSale();
    await montar(tester, repo);

    await tester.tap(find.byType(BotonDeCuenta));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupoSecondaryButton, 'Cerrar sesión'));
    await tester.pump();

    expect(repo.salidas, 1);
  });

  testWidgets('si salir falla, la hoja lo dice y se puede reintentar', (
    tester,
  ) async {
    final repo = _RepoQueSale(falla: true);
    await montar(tester, repo);

    await tester.tap(find.byType(BotonDeCuenta));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupoSecondaryButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(CupoErrorBanner), findsOneWidget);
    expect(
      find.widgetWithText(CupoSecondaryButton, 'Cerrar sesión'),
      findsOneWidget,
    );
  });
}

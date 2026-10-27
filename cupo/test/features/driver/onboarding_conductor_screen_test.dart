import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/driver/data/conductor_repository.dart';
import 'package:cupo/features/driver/data/zonas_repository.dart';
import 'package:cupo/features/driver/domain/vehiculo.dart';
import 'package:cupo/features/driver/domain/zona.dart';
import 'package:cupo/features/driver/presentation/onboarding_conductor_screen.dart';
import 'package:cupo/features/driver/presentation/vehiculo_screen.dart';
import 'package:cupo/features/driver/presentation/zonas_trabajo_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

class _ConductorFalso extends ConductorRepository {
  _ConductorFalso(this.vehiculo);

  Vehiculo? vehiculo;

  @override
  Future<Vehiculo?> miVehiculo() async => vehiculo;

  @override
  Future<Vehiculo> guardarVehiculo(
    VehiculoBorrador borrador, {
    String? id,
  }) async {
    return vehiculo = Vehiculo(
      id: 'nuevo',
      placa: borrador.placa,
      marca: borrador.marca,
      modelo: borrador.modelo,
      color: borrador.color,
      capacidad: borrador.capacidad,
    );
  }
}

class _ZonasFalsas extends ZonasRepository {
  @override
  Future<List<Zona>> catalogo() async => const [
    Zona(id: 'z1', nombre: 'Las Delicias', municipio: 'Maracaibo'),
  ];

  @override
  Future<Set<String>> misZonas() async => {};
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> montar(WidgetTester tester, Vehiculo? vehiculo) async {
    await montarPantalla(
      tester,
      OnboardingConductorScreen(
        conductor: _ConductorFalso(vehiculo),
        zonas: _ZonasFalsas(),
      ),
      usuario: usuarioDePrueba(rol: RolUsuario.conductor),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin vehículo, empieza por registrarlo y después pasa a las '
      'zonas', (tester) async {
    await montar(tester, null);

    expect(find.byType(VehiculoScreen), findsOneWidget);
    expect(find.text('Primero, tu vehículo'), findsOneWidget);
    expect(find.byType(ZonasTrabajoScreen), findsNothing);

    Future<void> escribir(String hint, String texto) async {
      final campo = find.widgetWithText(TextField, hint);
      await tester.ensureVisible(campo);
      await tester.enterText(campo, texto);
    }

    await escribir('AB123CD', 'AB123CD');
    await escribir('Toyota', 'Toyota');
    await escribir('Hiace', 'Hiace');
    await escribir('Blanco', 'Blanca');
    final continuar = find.widgetWithText(CupoPrimaryButton, 'Continuar');
    await tester.ensureVisible(continuar);
    await tester.tap(continuar);
    await tester.pumpAndSettle();

    expect(find.byType(ZonasTrabajoScreen), findsOneWidget);
  });

  testWidgets('con vehículo ya registrado, va directo a las zonas', (
    tester,
  ) async {
    await montar(
      tester,
      const Vehiculo(
        id: 'v1',
        placa: 'AB123CD',
        marca: 'Toyota',
        modelo: 'Hiace',
        color: 'Blanca',
        capacidad: 14,
      ),
    );

    expect(find.byType(ZonasTrabajoScreen), findsOneWidget);
    expect(find.byType(VehiculoScreen), findsNothing);
  });
}

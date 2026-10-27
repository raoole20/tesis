import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/driver/data/conductor_repository.dart';
import 'package:cupo/features/driver/domain/vehiculo.dart';
import 'package:cupo/features/driver/presentation/campos_vehiculo.dart';
import 'package:cupo/features/driver/presentation/perfil_conductor_screen.dart';
import 'package:cupo/features/driver/presentation/vehiculo_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

const _hiace = Vehiculo(
  id: 'v1',
  placa: 'AB123CD',
  marca: 'Toyota',
  modelo: 'Hiace',
  color: 'Blanca',
  capacidad: 14,
  anio: 2015,
);

/// Guarda en memoria lo que la pantalla le manda.
class _ConductorFalso extends ConductorRepository {
  _ConductorFalso({this.vehiculo, this.fallaAlGuardar});

  Vehiculo? vehiculo;
  final String? fallaAlGuardar;

  VehiculoBorrador? guardado;
  String? idGuardado;
  String? licencia;
  DateTime? venceEn;

  @override
  Future<Vehiculo?> miVehiculo() async => vehiculo;

  @override
  Future<({String? numero, DateTime? venceEn})> miLicencia() async =>
      (numero: null, venceEn: null);

  @override
  Future<Vehiculo> guardarVehiculo(
    VehiculoBorrador borrador, {
    String? id,
  }) async {
    final falla = fallaAlGuardar;
    if (falla != null) throw ConductorFallo(falla);
    guardado = borrador;
    idGuardado = id;
    return vehiculo = Vehiculo(
      id: id ?? 'nuevo',
      placa: borrador.placa,
      marca: borrador.marca,
      modelo: borrador.modelo,
      color: borrador.color,
      capacidad: borrador.capacidad,
      anio: borrador.anio,
    );
  }

  @override
  Future<void> guardarLicencia({
    required String numero,
    required DateTime venceEn,
  }) async {
    licencia = numero;
    this.venceEn = venceEn;
  }
}

class _AuthFalso extends AuthRepository {
  int envios = 0;

  @override
  Future<void> enviarARevision() async => envios++;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final hoy = DateTime(2026, 10, 26);

  Future<void> escribir(WidgetTester tester, String hint, String texto) async {
    final campo = find.widgetWithText(TextField, hint);
    await tester.ensureVisible(campo);
    await tester.enterText(campo, texto);
  }

  /// [esperar] en `false` para los envíos que dejan el botón cargando: sin
  /// AuthGate que cambie de pantalla, la animación no termina nunca.
  Future<void> tocar(
    WidgetTester tester,
    String rotulo, {
    bool esperar = true,
  }) async {
    final boton = find.widgetWithText(CupoPrimaryButton, rotulo);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    esperar ? await tester.pumpAndSettle() : await tester.pump();
  }

  Future<void> tocarPaso(WidgetTester tester, String mensaje) async {
    final boton = find.byTooltip(mensaje);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
  }

  Future<void> llenarVehiculo(WidgetTester tester) async {
    await escribir(tester, 'AB123CD', 'ab-123 cd');
    await escribir(tester, 'Toyota', 'Toyota');
    await escribir(tester, 'Hiace', 'Hiace');
    await escribir(tester, '2015', '2015');
    await escribir(tester, 'Blanco', 'Blanca');
  }

  group('VehiculoScreen', () {
    testWidgets('registra un vehículo nuevo con la placa normalizada', (
      tester,
    ) async {
      final repo = _ConductorFalso();
      Vehiculo? devuelto;

      await montarPantalla(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                devuelto = await Navigator.of(context).push<Vehiculo>(
                  MaterialPageRoute(
                    builder: (_) => VehiculoScreen(repositorio: repo, hoy: hoy),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar vehículo'), findsOneWidget);
      await llenarVehiculo(tester);
      // De 4 puestos a 6.
      await tocarPaso(tester, 'Un puesto más');
      await tocarPaso(tester, 'Un puesto más');
      expect(find.text('6 puestos'), findsOneWidget);

      await tocar(tester, 'Registrar vehículo');

      expect(repo.guardado?.placa, 'AB123CD');
      expect(repo.guardado?.capacidad, 6);
      expect(repo.guardado?.anio, 2015);
      expect(repo.idGuardado, isNull);
      // Cerró la pantalla y devolvió lo guardado.
      expect(find.text('abrir'), findsOneWidget);
      expect(devuelto?.placa, 'AB123CD');
    });

    testWidgets('precarga el vehículo existente y lo actualiza', (
      tester,
    ) async {
      final repo = _ConductorFalso(vehiculo: _hiace);
      await montarPantalla(tester, VehiculoScreen(repositorio: repo, hoy: hoy));
      await tester.pumpAndSettle();

      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('14 puestos'), findsOneWidget);
      await tocarPaso(tester, 'Un puesto menos');
      await tocar(tester, 'Guardar cambios');

      expect(repo.idGuardado, 'v1');
      expect(repo.guardado?.capacidad, 13);
    });

    testWidgets('no guarda con la placa mal escrita', (tester) async {
      final repo = _ConductorFalso();
      await montarPantalla(tester, VehiculoScreen(repositorio: repo, hoy: hoy));
      await tester.pumpAndSettle();

      await llenarVehiculo(tester);
      await escribir(tester, 'AB123CD', 'AB12');
      await tocar(tester, 'Registrar vehículo');

      expect(
        find.text('La placa lleva 6 o 7 letras y números, como AB123CD.'),
        findsOneWidget,
      );
      expect(repo.guardado, isNull);
    });

    testWidgets('muestra el error del servidor', (tester) async {
      final repo = _ConductorFalso(
        fallaAlGuardar: 'Esa placa ya está registrada.',
      );
      await montarPantalla(tester, VehiculoScreen(repositorio: repo, hoy: hoy));
      await tester.pumpAndSettle();

      await llenarVehiculo(tester);
      await tocar(tester, 'Registrar vehículo');

      expect(find.text('Esa placa ya está registrada.'), findsOneWidget);
    });
  });

  group('SelectorCapacidad', () {
    testWidgets('no baja de un puesto', (tester) async {
      await montarPantalla(
        tester,
        Scaffold(body: SelectorCapacidad(valor: 1, onCambiar: (_) {})),
      );

      IconButton boton(String mensaje) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(mensaje),
          matching: find.byType(IconButton),
        ),
      );
      expect(boton('Un puesto menos').onPressed, isNull);
      expect(boton('Un puesto más').onPressed, isNotNull);
      expect(find.text('1 puesto'), findsOneWidget);
    });
  });

  group('PerfilConductorScreen', () {
    Future<(_ConductorFalso, _AuthFalso)> montar(WidgetTester tester) async {
      final repo = _ConductorFalso();
      final auth = _AuthFalso();
      await montarPantalla(
        tester,
        PerfilConductorScreen(repositorio: repo, autenticacion: auth, hoy: hoy),
        usuario: usuarioDePrueba(
          rol: RolUsuario.conductor,
          estado: EstadoCuenta.perfilIncompleto,
        ),
        repositorio: auth,
      );
      await tester.pumpAndSettle();
      return (repo, auth);
    }

    testWidgets('pide la licencia vigente antes de seguir', (tester) async {
      await montar(tester);

      expect(find.text('Tu licencia'), findsOneWidget);
      await escribir(tester, 'V-12345678', 'V-20111222');
      await escribir(tester, 'DD/MM/AAAA', '01012020');
      expect(find.text('01/01/2020'), findsOneWidget);
      await tocar(tester, 'Continuar');

      expect(find.text('Tu licencia está vencida.'), findsOneWidget);
      expect(find.text('¿En qué llevas a los estudiantes?'), findsNothing);
    });

    testWidgets('guarda licencia y vehículo y envía a revisión', (
      tester,
    ) async {
      final (repo, auth) = await montar(tester);

      await escribir(tester, 'V-12345678', 'V-20111222');
      await escribir(tester, 'DD/MM/AAAA', '15032027');
      await tocar(tester, 'Continuar');

      expect(find.text('¿En qué llevas a los estudiantes?'), findsOneWidget);
      await llenarVehiculo(tester);
      await tocar(tester, 'Enviar a revisión', esperar: false);
      await tester.pump();

      expect(repo.licencia, 'V-20111222');
      expect(repo.venceEn, DateTime(2027, 3, 15));
      expect(repo.guardado?.placa, 'AB123CD');
      expect(auth.envios, 1);
    });
  });
}

import 'dart:async';

import 'package:cupo/features/spike_rastreo/data/canal_dispositivo.dart';
import 'package:cupo/features/spike_rastreo/data/fuente_de_ubicacion.dart';
import 'package:cupo/features/spike_rastreo/data/spike_rastreo_repository.dart';
import 'package:cupo/features/spike_rastreo/domain/reporte_fase.dart';
import 'package:cupo/features/spike_rastreo/presentation/prueba_rastreo_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

class _UbicacionFalsa extends FuenteDeUbicacion {
  _UbicacionFalsa();

  final gps = StreamController<Position>.broadcast();
  LocationPermission permisoActual = LocationPermission.whileInUse;
  bool? wakelockPedido;

  @override
  Future<bool> servicioActivo() async => true;

  @override
  Future<LocationPermission> permiso() async => permisoActual;

  @override
  Future<LocationPermission> pedirPermiso() async => permisoActual;

  @override
  Stream<Position> posiciones({
    required Duration intervalo,
    required bool wakelock,
    required String tituloAviso,
    required String textoAviso,
    Color? acento,
  }) {
    wakelockPedido = wakelock;
    return gps.stream;
  }
}

class _CanalFalso extends CanalDispositivo {
  _CanalFalso();

  bool? pantallaFija;

  @override
  Future<InfoDispositivo?> info() async => const InfoDispositivo(
    fabricante: 'Google',
    modelo: 'Pixel 7',
    android: '14',
    sdk: 34,
    bateriaSinRestriccion: false,
  );

  @override
  Future<bool> pedirNotificaciones() async => true;

  @override
  Future<bool?> pantallaEncendida() async => true;

  @override
  Future<void> mantenerPantallaEncendida(bool activo) async {
    pantallaFija = activo;
  }

  @override
  Future<bool> avisar({required String titulo, required String texto}) async =>
      true;
}

class _RepoFalso extends SpikeRastreoRepository {
  final List<Map<String, Object?>> filas = [];

  @override
  Future<void> insertar(List<Map<String, Object?>> filas) async {
    this.filas.addAll(filas);
  }

  @override
  Future<List<ReporteFase>> reporte(String sesionId) async => [
    ReporteFase.fromMap({
      'fase': '1_primer_plano',
      'completa': false,
      'duracion_s': 4,
      'esperadas': 0,
      'recibidas': 1,
      'cobertura_pct': null,
      'brecha_max_s': 4,
      'brecha_p95_s': 4,
      'perdidas': 0,
      'tardias': 0,
      'latencia_mediana_s': 0.4,
      'estados': 'resumed 1',
      'cumple': null,
    }),
  ];
}

Position _posicion() => Position(
  latitude: 10.6978,
  longitude: -71.6335,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _UbicacionFalsa ubicacion;
  late _CanalFalso canal;
  late _RepoFalso repo;

  Future<void> montar(WidgetTester tester) async {
    ubicacion = _UbicacionFalsa();
    canal = _CanalFalso();
    repo = _RepoFalso();
    await montarPantalla(
      tester,
      PruebaRastreoScreen(
        repositorio: repo,
        ubicacion: ubicacion,
        canal: canal,
      ),
    );
    await tester.pump();
  }

  /// Desmonta la pantalla para que su reloj de un segundo no quede vivo.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('antes de empezar muestra las opciones y el estado del '
      'teléfono', (tester) async {
    await montar(tester);

    expect(find.text('Prueba de rastreo'), findsOneWidget);
    expect(find.text('2 minutos por fase'), findsOneWidget);
    expect(find.text('10 minutos por fase'), findsOneWidget);
    expect(find.text('20 minutos por fase'), findsOneWidget);
    expect(find.text('Google Pixel 7 · Android 14 (API 34)'), findsOneWidget);
    expect(find.text('Ubicación: mientras se usa la app'), findsOneWidget);
    expect(find.text('Permitir todo el tiempo'), findsOneWidget);
    expect(
      find.text('Batería: optimizada (Android puede frenar a Cupo)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(CupoPrimaryButton, 'Empezar prueba'),
      findsOneWidget,
    );

    await desmontar(tester);
  });

  testWidgets('al empezar busca el GPS y con la primera ubicación arranca la '
      'fase 1 y envía la muestra', (tester) async {
    await montar(tester);

    await tester.tap(find.text('2 minutos por fase'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CupoPrimaryButton, 'Empezar prueba'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Buscando señal GPS…'), findsOneWidget);
    expect(canal.pantallaFija, isTrue);
    expect(ubicacion.wakelockPedido, isTrue);

    ubicacion.gps.add(_posicion());
    await tester.pump();
    await tester.pump();

    expect(find.text('FASE 1 DE 3'), findsOneWidget);
    expect(find.text('Deja Cupo abierta'), findsWidgets);
    expect(repo.filas, hasLength(1));
    expect(repo.filas.single['duracion_fase_s'], 120);
    expect(repo.filas.single['permiso'], 'mientras_se_usa');
    expect(
      repo.filas.single['dispositivo'],
      'Google Pixel 7 · Android 14 (API 34)',
    );
    expect(find.text('Horario de la prueba'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('detener pide confirmación y muestra el resultado parcial', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.widgetWithText(CupoPrimaryButton, 'Empezar prueba'));
    await tester.pump();
    await tester.pump();
    ubicacion.gps.add(_posicion());
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.widgetWithText(CupoSecondaryButton, 'Detener prueba'),
    );
    await tester.pump();
    expect(find.text('¿Detener la prueba?'), findsOneWidget);

    await tester.tap(find.text('Detener'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Prueba detenida antes de tiempo'), findsOneWidget);
    expect(find.text('Incompleta'), findsOneWidget);
    expect(canal.pantallaFija, isFalse);
    expect(
      find.widgetWithText(CupoPrimaryButton, 'Nueva prueba'),
      findsOneWidget,
    );

    await desmontar(tester);
  });

  testWidgets('con el permiso bloqueado no arranca y ofrece ir a Ajustes', (
    tester,
  ) async {
    await montar(tester);
    ubicacion.permisoActual = LocationPermission.deniedForever;

    await tester.tap(find.widgetWithText(CupoPrimaryButton, 'Empezar prueba'));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Cupo tiene la ubicación bloqueada'),
      findsOneWidget,
    );
    expect(find.text('Abrir Ajustes'), findsOneWidget);
    expect(find.text('Buscando señal GPS…'), findsNothing);

    await desmontar(tester);
  });
}

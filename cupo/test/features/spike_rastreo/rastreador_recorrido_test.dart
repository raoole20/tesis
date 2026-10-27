import 'dart:async';
import 'dart:math';

import 'package:cupo/features/spike_rastreo/data/canal_dispositivo.dart';
import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/presentation/rastreador_de_prueba.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _Banco {
  _Banco() {
    rastreador = RastreadorDePrueba(
      abrirPosiciones: (_) => gps.stream,
      enviar: (filas) async => enviadas.addAll(filas),
      estadoApp: () => EstadoApp.paused,
      estadoTelefono: () async => const EstadoAlCapturar(
        pantallaEncendida: false,
        bateriaPct: 77,
        cargando: true,
      ),
      reloj: () => ahora,
      azar: Random(3),
      registrarSesion: (sesion) async {
        intentosDeRegistro++;
        if (registroFalla) throw Exception('sin red');
        registradas.add(sesion);
      },
      periodoReloj: const Duration(days: 1),
    );
  }

  late final RastreadorDePrueba rastreador;
  final gps = StreamController<Position>();
  DateTime ahora = DateTime.utc(2026, 10, 27, 13);
  final List<Map<String, Object?>> enviadas = [];
  final List<SesionRastreo> registradas = [];
  int intentosDeRegistro = 0;
  bool registroFalla = false;

  static const config = ConfigPrueba(
    modo: ModoPrueba.recorrido,
    wakelock: true,
    permiso: PermisoRastreo.mientrasSeUsa,
  );

  Future<void> ubicacion(
    double lat,
    double lng, {
    double rumbo = 0,
    double velocidad = 0,
  }) async {
    gps.add(
      Position(
        latitude: lat,
        longitude: lng,
        timestamp: ahora,
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: rumbo,
        headingAccuracy: 0,
        speed: velocidad,
        speedAccuracy: 0,
      ),
    );
    await pumpEventQueue();
  }
}

void main() {
  late _Banco banco;

  setUp(() => banco = _Banco());
  tearDown(() => banco.rastreador.dispose());

  test('en un recorrido no hay fases ni fin por reloj', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion(10.70, -71.60);

    banco.ahora = banco.ahora.add(const Duration(hours: 2));
    r.revisarReloj();
    await banco.ubicacion(10.701, -71.60);

    expect(r.etapa, EtapaPrueba.enCurso);
    expect(r.esRecorrido, isTrue);
    expect(r.fase, isNull);
    expect(r.transcurrido, const Duration(hours: 2));
    final fila = banco.enviadas.last;
    expect(fila['modo'], 'recorrido');
    expect(fila['fase'], 'recorrido');
    expect(fila['duracion_fase_s'], isNull);
    expect(fila['bateria_pct'], 77);
    expect(fila['cargando'], true);
    expect(fila['pantalla_encendida'], false);
  });

  test('terminar deja la marca de cierre con el seq siguiente y suelta el '
      'GPS', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion(10.70, -71.60);
    banco.ahora = banco.ahora.add(const Duration(seconds: 5));
    await banco.ubicacion(10.7005, -71.60);

    banco.ahora = banco.ahora.add(const Duration(seconds: 40));
    await r.terminarRecorrido();
    await pumpEventQueue();

    expect(r.etapa, EtapaPrueba.terminada);
    expect(banco.gps.hasListener, isFalse);
    final cierre = banco.enviadas.last;
    expect(cierre['cierre'], true);
    expect(cierre['seq'], 3);
    expect(cierre['capturada_en'], banco.ahora.toIso8601String());
    expect(banco.enviadas.where((f) => f['cierre'] == false), hasLength(2));
  });

  test('el rumbo sale del GPS en marcha y del azimut si está quieto', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion(10.70, -71.60, rumbo: 200, velocidad: 9);
    expect(banco.enviadas.last['rumbo_deg'], 200);
    expect(banco.enviadas.last['rumbo_calculado'], false);
    expect(banco.enviadas.last['velocidad_ms'], 9);

    // Hacia el este, con el GPS diciendo 0 y sin velocidad.
    await banco.ubicacion(10.70, -71.599);
    expect(banco.enviadas.last['rumbo_deg'] as double, closeTo(90, 0.1));
    expect(banco.enviadas.last['rumbo_calculado'], true);

    // Quieta en un semáforo: conserva el último rumbo.
    await banco.ubicacion(10.70, -71.599);
    expect(banco.enviadas.last['rumbo_deg'] as double, closeTo(90, 0.1));

    expect(r.distanciaM, closeTo(109, 2));
    expect(r.recorridoLocal, hasLength(3));
    expect(r.ultima?.rumboDeg, closeTo(90, 0.1));
  });

  test('registra el plan una vez, y si falla lo reintenta', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    banco.registroFalla = true;
    await banco.ubicacion(10.70, -71.60);
    expect(banco.registradas, isEmpty);

    banco.registroFalla = false;
    r.revisarReloj();
    await pumpEventQueue();
    await banco.ubicacion(10.7001, -71.60);
    r.revisarReloj();
    await pumpEventQueue();

    expect(banco.registradas, hasLength(1));
    expect(banco.registradas.single.modo, ModoPrueba.recorrido);
    expect(banco.intentosDeRegistro, 2);
  });
}

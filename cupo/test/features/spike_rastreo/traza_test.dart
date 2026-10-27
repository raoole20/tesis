import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/reporte_ruta.dart';
import 'package:cupo/features/spike_rastreo/domain/traza.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 10, 27, 13);

/// Un punto que avanza hacia el norte: [metros] desde el origen.
PuntoTraza _p(int seq, int segundos, double metros, {bool cierre = false}) =>
    PuntoTraza(
      seq: seq,
      punto: PuntoGeo(10.7 + metros / 111195, -71.6),
      capturadaEn: _t0.add(Duration(seconds: segundos)),
      estadoApp: EstadoApp.paused,
      cierre: cierre,
    );

void main() {
  group('tramosDeTraza', () {
    test('cada 5 s y 50 m no hay brechas', () {
      final tramos = tramosDeTraza([
        for (var i = 0; i < 5; i++) _p(i + 1, i * 5, i * 50.0),
      ]);
      expect(tramos, hasLength(4));
      expect(tramos.every((t) => !t.esBrecha), isTrue);
      expect(tramos.first.segundos, 5);
      expect(tramos.first.metros, closeTo(50, 0.5));
    });

    test('más de 30 s sin muestras es brecha, aunque no se mueva', () {
      final tramos = tramosDeTraza([_p(1, 0, 0), _p(2, 31, 0), _p(3, 61, 0)]);
      expect(tramos.map((t) => t.esBrecha), [true, false]);
    });

    test('un salto de más de 500 m también es brecha', () {
      final tramos = tramosDeTraza([_p(1, 0, 0), _p(2, 20, 600)]);
      expect(tramos.single.esBrecha, isTrue);
      expect(tramos.single.metros, closeTo(600, 1));
    });

    test('la marca de cierre no es una muestra', () {
      final tramos = tramosDeTraza([
        _p(1, 0, 0),
        _p(2, 5, 50),
        _p(3, 300, 50, cierre: true),
      ]);
      expect(tramos, hasLength(1));
    });

    test('ordena por hora aunque lleguen desordenadas', () {
      final tramos = tramosDeTraza([_p(2, 5, 50), _p(1, 0, 0)]);
      expect(tramos.single.desde.seq, 1);
    });
  });

  test('trazosDelMapa junta tramos seguidos del mismo tipo', () {
    final tramos = tramosDeTraza([
      _p(1, 0, 0),
      _p(2, 5, 50),
      _p(3, 10, 100),
      _p(4, 70, 150), // brecha de 60 s
      _p(5, 75, 200),
    ]);
    final trazos = trazosDelMapa(tramos);

    expect(trazos.map((t) => t.esBrecha), [false, true, false]);
    expect(trazos[0].puntos, hasLength(3));
    // Continuos: cada trazo empieza donde terminó el anterior.
    expect(trazos[1].puntos.first, trazos[0].puntos.last);
    expect(trazos[2].puntos.first, trazos[1].puntos.last);
  });

  group('flechasDeSentido', () {
    test('una cada 300 m, empezando a la mitad del primer tramo', () {
      final linea = [
        for (var i = 0; i <= 10; i++) PuntoGeo(10.7 + i * 100 / 111195, -71.6),
      ]; // 1 km hacia el norte
      final flechas = flechasDeSentido(linea);

      expect(flechas, hasLength(3)); // a 150, 450 y 750 m
      expect(
        distanciaMetros(linea.first, flechas.first.punto),
        closeTo(150, 1),
      );
      for (final f in flechas) {
        expect(f.rumbo, closeTo(0, 0.01));
      }
    });

    test('de vuelta apuntan al revés: distingue la ida de la vuelta', () {
      final ida = [const PuntoGeo(10.7, -71.6), const PuntoGeo(10.7, -71.59)];
      final vuelta = ida.reversed.toList();
      expect(flechasDeSentido(ida).first.rumbo, closeTo(90, 0.1));
      expect(flechasDeSentido(vuelta).first.rumbo, closeTo(270, 0.1));
    });

    test('sin línea no hay flechas', () {
      expect(flechasDeSentido(const []), isEmpty);
      expect(flechasDeSentido(const [PuntoGeo(1, 1)]), isEmpty);
    });
  });

  test('contextoDe sigue el criterio de spike_reporte_ruta()', () {
    expect(contextoDe(EstadoApp.resumed, true), ContextoDeUso.primerPlano);
    expect(contextoDe(EstadoApp.inactive, null), ContextoDeUso.primerPlano);
    expect(contextoDe(EstadoApp.paused, true), ContextoDeUso.segundoPlano);
    expect(contextoDe(EstadoApp.hidden, null), ContextoDeUso.segundoPlano);
    expect(contextoDe(EstadoApp.resumed, false), ContextoDeUso.pantallaApagada);
    expect(contextoDe(EstadoApp.paused, false), ContextoDeUso.pantallaApagada);
  });

  test('PuntoTraza.fromMap lee una fila de spike_posiciones', () {
    final p = PuntoTraza.fromMap({
      'seq': 7,
      'lat': 10.7,
      'lng': -71.6,
      'capturada_en': '2026-10-27T13:00:05+00:00',
      'estado_app': 'paused',
      'pantalla_encendida': false,
      'rumbo_deg': 270,
      'cierre': false,
    });
    expect(p.seq, 7);
    expect(p.punto, const PuntoGeo(10.7, -71.6));
    expect(p.estadoApp, EstadoApp.paused);
    expect(p.rumboDeg, 270.0);
    expect(p.capturadaEn, DateTime.utc(2026, 10, 27, 13, 0, 5));
  });

  group('ReporteRuta', () {
    // La salida real de spike_reporte_ruta() sobre la traza sintética pegada
    // a la ruta (verificación del 26-oct-2026, en una transacción revertida).
    final fila = <String, dynamic>{
      'completa': true,
      'inicio': '2026-10-27T01:05:42.853321+00:00',
      'fin': '2026-10-27T01:14:07.853321+00:00',
      'duracion_s': 505,
      'distancia_m': 5275,
      'velocidad_media_kmh': 37.6,
      'velocidad_max_gps_kmh': 39.2,
      'velocidad_max_traza_kmh': 39.3,
      'esperadas': 101,
      'recibidas': 88,
      'cobertura_pct': 87.1,
      'brecha_max_s': 65,
      'brecha_max_en': '2026-10-27T01:08:57.853321+00:00',
      'brecha_max_m': 686,
      'brecha_p95_s': 5,
      'brechas_largas': 1,
      'pct_primer_plano': 0,
      'pct_segundo_plano': 51.5,
      'pct_pantalla_apagada': 48.5,
      'cobertura_primer_plano': null,
      'cobertura_segundo_plano': 76.9,
      'cobertura_pantalla_apagada': 98,
      'precision_p50_m': 6,
      'precision_p95_m': 6,
      'perdidas': 0,
      'tardias': 0,
      'latencia_mediana_s': 1522.5,
      'pct_cargando': 0,
      'bateria_inicio_pct': 90,
      'bateria_fin_pct': 86,
      'ruta_planificada_m': 5386,
      'desvio_mediana_m': 0,
      'desvio_p95_m': 0,
      'desvio_max_m': 0,
      'pct_muestras_cerca_ruta': 100,
      'pct_ruta_cubierta': 88.6,
      'dom_radio_m': 1500,
      'dom_distancia_min_m': 70,
      'dom_entrada_en': '2026-10-27T01:11:37.853321+00:00',
      'dom_entrada_m': 1486,
      'dom_brecha_previa_s': 5,
      'dom_muestras_alrededor': 25,
      'dom_aviso_a_tiempo': true,
      'cumple': false,
    };

    test('fromMap lee la salida real de la función', () {
      final r = ReporteRuta.fromMap(fila);
      expect(r.completa, isTrue);
      expect(r.cumple, isFalse);
      expect(r.brechaMaxS, 65);
      expect(r.brechaMaxM, 686);
      expect(r.coberturaPrimerPlano, isNull);
      expect(r.pctRutaCubierta, 88.6);
      expect(r.domAvisoATiempo, isTrue);
      expect(r.bateriaFinPct, 86);
      expect(r.pctFueraDeVista, 100);
      expect(r.pocoSegundoPlano, isFalse);
    });

    test('un recorrido casi todo a la vista no prueba el segundo plano', () {
      final r = ReporteRuta.fromMap({
        ...fila,
        'pct_primer_plano': 80,
        'pct_segundo_plano': '15.0',
        'pct_pantalla_apagada': 5,
      });
      expect(r.pctFueraDeVista, 20);
      expect(r.pocoSegundoPlano, isTrue);
    });

    test('el criterio es el mismo que el de la función SQL', () {
      expect(CriterioRuta.coberturaMinima, 90);
      expect(CriterioRuta.brechaMaximaS, 30);
      expect(CriterioRuta.brechaMaximaM, 500);
      expect(CriterioRuta.radioAvisoM, 1500);
    });
  });
}

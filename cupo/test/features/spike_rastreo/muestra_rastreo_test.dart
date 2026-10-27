import 'dart:io';
import 'dart:math';

import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/protocolo_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/reporte_fase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sesion = SesionRastreo(
    id: '6f1c2a4e-0b7d-4c3e-9a51-2d8e7f6a5b40',
    // -04:00, la hora de Venezuela.
    inicio: DateTime.parse('2026-10-26T10:00:00-04:00'),
    protocolo: const ProtocoloRastreo(duracionFase: Duration(minutes: 10)),
    wakelock: true,
    permiso: PermisoRastreo.mientrasSeUsa,
    bateriaSinRestriccion: false,
    dispositivo: 'samsung SM-A515F · Android 13 (API 33)',
  );

  final muestra = MuestraRastreo(
    seq: 42,
    lat: 10.6978,
    lng: -71.6335,
    precisionM: 4.5,
    fijadaEn: DateTime.parse('2026-10-26T10:03:29-04:00'),
    capturadaEn: DateTime.parse('2026-10-26T10:03:30-04:00'),
    estadoApp: EstadoApp.paused,
    pantallaEncendida: false,
    fase: FaseRastreo.primerPlano,
  );

  group('fila de spike_posiciones', () {
    final fila = muestra.fila(
      sesion,
      intentos: 3,
      enviadaEn: DateTime.parse('2026-10-26T10:04:00-04:00'),
    );

    test('trae exactamente las columnas que la migración deja insertar', () {
      // El `grant insert (...)` de 20261026000001_spike_rastreo.sql. Si una
      // columna sobra, PostgREST rechaza la fila entera.
      final migracion = File(
        '../supabase/migrations/20261026000001_spike_rastreo.sql',
      ).readAsStringSync();
      final grant = RegExp(r'grant insert \(([^)]*)\)')
          .firstMatch(migracion)!
          .group(1)!;
      final permitidas = grant
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toSet();

      expect(fila.keys.toSet(), permitidas);
    });

    test('las horas van en UTC y conservan el instante', () {
      expect(fila['capturada_en'], '2026-10-26T14:03:30.000Z');
      expect(fila['enviada_en'], '2026-10-26T14:04:00.000Z');
      expect(fila['fijada_en'], '2026-10-26T14:03:29.000Z');
      expect(fila['sesion_inicio'], '2026-10-26T14:00:00.000Z');
    });

    test('lleva la sesión, el envío y la muestra', () {
      expect(fila['sesion_id'], sesion.id);
      expect(fila['duracion_fase_s'], 600);
      expect(fila['intervalo_s'], 5);
      expect(fila['permiso'], 'mientras_se_usa');
      expect(fila['seq'], 42);
      expect(fila['intentos'], 3);
      expect(fila['estado_app'], 'paused');
      expect(fila['pantalla_encendida'], false);
      expect(fila['fase'], '1_primer_plano');
    });
  });

  test('los enums usan los valores de los check de la migración', () {
    expect(EstadoApp.values.map((e) => e.valor), [
      'resumed',
      'inactive',
      'paused',
      'hidden',
      'detached',
    ]);
    expect(PermisoRastreo.values.map((p) => p.valor), [
      'mientras_se_usa',
      'siempre',
    ]);
  });

  test('nuevoId da UUID v4 válidos y distintos', () {
    final azar = Random(7);
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) SesionRastreo.nuevoId(azar)};

    expect(ids, hasLength(200));
    for (final id in ids) {
      expect(id, matches(uuid));
    }
  });

  group('reporte', () {
    Map<String, dynamic> fila(
      String fase, {
      bool completa = true,
      Object? cobertura = 98.3,
      Object? brecha = 6.0,
      bool? cumple = true,
    }) => {
      'fase': fase,
      'completa': completa,
      'duracion_s': 600,
      'esperadas': 120,
      'recibidas': 118,
      'cobertura_pct': cobertura,
      'brecha_max_s': brecha,
      'brecha_p95_s': 5,
      'perdidas': 0,
      'tardias': 1,
      'latencia_mediana_s': '0.8',
      'estados': 'paused 118',
      'cumple': cumple,
    };

    test('fromMap acepta numeric como número o como texto', () {
      final f = ReporteFase.fromMap(fila('2_minimizada', cobertura: '98.3'));
      expect(f.fase, FaseRastreo.minimizada);
      expect(f.coberturaPct, 98.3);
      expect(f.brechaMaxS, 6.0);
      expect(f.brechaP95S, 5.0);
      expect(f.latenciaMedianaS, 0.8);
      expect(f.cumple, isTrue);
    });

    List<ReporteFase> tres({bool? cumple3 = true, bool completa3 = true}) => [
      ReporteFase.fromMap(fila('1_primer_plano')),
      ReporteFase.fromMap(fila('2_minimizada')),
      ReporteFase.fromMap(
        fila('3_pantalla_apagada', completa: completa3, cumple: cumple3),
      ),
    ];

    test('el veredicto exige las tres fases completas y cumpliendo', () {
      expect(veredictoRastreo(tres()), isTrue);
      expect(veredictoRastreo(tres(cumple3: false)), isFalse);
      expect(veredictoRastreo(tres(completa3: false)), isNull);
      expect(veredictoRastreo(tres().take(2).toList()), isNull);
    });

    test('una fase completa que falla decide aunque falte otra', () {
      final fases = [
        ReporteFase.fromMap(fila('1_primer_plano', cumple: false)),
        ReporteFase.fromMap(fila('2_minimizada', completa: false)),
      ];
      expect(veredictoRastreo(fases), isFalse);
    });

    test('el criterio es 90 % de cobertura y 30 s de brecha', () {
      expect(CriterioRastreo.coberturaMinima, 90);
      expect(CriterioRastreo.brechaMaxima, 30);
      final migracion = File(
        '../supabase/migrations/20261026000001_spike_rastreo.sql',
      ).readAsStringSync();
      expect(migracion, contains('p_cobertura_min numeric default 90'));
      expect(migracion, contains('p_brecha_max_s  numeric default 30'));
    });
  });
}

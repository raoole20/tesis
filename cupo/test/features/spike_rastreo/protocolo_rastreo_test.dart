import 'package:cupo/features/spike_rastreo/domain/protocolo_rastreo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const estandar = ProtocoloRastreo(duracionFase: Duration(minutes: 10));
  const corta = ProtocoloRastreo(duracionFase: Duration(minutes: 2));

  group('faseEn', () {
    test('las tres fases se reparten el tiempo en partes iguales', () {
      expect(estandar.faseEn(Duration.zero), FaseRastreo.primerPlano);
      expect(
        estandar.faseEn(const Duration(minutes: 9, seconds: 59)),
        FaseRastreo.primerPlano,
      );
      expect(
        estandar.faseEn(const Duration(minutes: 10)),
        FaseRastreo.minimizada,
      );
      expect(
        estandar.faseEn(const Duration(minutes: 19, seconds: 59)),
        FaseRastreo.minimizada,
      );
      expect(
        estandar.faseEn(const Duration(minutes: 20)),
        FaseRastreo.pantallaApagada,
      );
      expect(
        estandar.faseEn(const Duration(minutes: 29, seconds: 59)),
        FaseRastreo.pantallaApagada,
      );
    });

    test('al cumplirse el total la prueba terminó', () {
      expect(estandar.faseEn(const Duration(minutes: 30)), isNull);
      expect(estandar.faseEn(const Duration(hours: 2)), isNull);
    });

    test('si el reloj retrocede, cuenta como el principio', () {
      expect(
        estandar.faseEn(const Duration(seconds: -3)),
        FaseRastreo.primerPlano,
      );
    });

    test('la duración corta cambia de fase cada 2 minutos', () {
      expect(corta.faseEn(const Duration(minutes: 2)), FaseRastreo.minimizada);
      expect(
        corta.faseEn(const Duration(minutes: 4)),
        FaseRastreo.pantallaApagada,
      );
      expect(corta.faseEn(const Duration(minutes: 6)), isNull);
    });
  });

  test('cada fase empieza donde termina la anterior', () {
    for (final fase in FaseRastreo.values) {
      expect(
        estandar.finDe(fase) - estandar.inicioDe(fase),
        estandar.duracionFase,
      );
    }
    expect(
      estandar.inicioDe(FaseRastreo.minimizada),
      estandar.finDe(FaseRastreo.primerPlano),
    );
    expect(estandar.finDe(FaseRastreo.pantallaApagada), estandar.total);
    expect(estandar.total, const Duration(minutes: 30));
  });

  test('restanteEn cuenta hasta el próximo cambio de fase', () {
    expect(
      estandar.restanteEn(const Duration(minutes: 7, seconds: 30)),
      const Duration(minutes: 2, seconds: 30),
    );
    expect(
      estandar.restanteEn(const Duration(minutes: 10)),
      const Duration(minutes: 10),
    );
    expect(estandar.restanteEn(const Duration(minutes: 31)), Duration.zero);
  });

  test('esperadas por fase: duración entre intervalo de 5 s', () {
    expect(estandar.esperadasPorFase, 120);
    expect(corta.esperadasPorFase, 24);
    expect(
      const ProtocoloRastreo(duracionFase: Duration(minutes: 20))
          .esperadasPorFase,
      240,
    );
  });

  test('las duraciones ofrecidas son 2, 10 y 20 minutos', () {
    expect(DuracionPrueba.values.map((d) => d.porFase.inMinutes), [2, 10, 20]);
  });

  group('FaseRastreo', () {
    test('los valores son los del check de spike_posiciones.fase', () {
      expect(FaseRastreo.values.map((f) => f.valor), [
        '1_primer_plano',
        '2_minimizada',
        '3_pantalla_apagada',
      ]);
      expect(FaseRastreo.values.map((f) => f.numero), [1, 2, 3]);
    });

    test('desde() lee cada valor y rechaza uno desconocido', () {
      for (final fase in FaseRastreo.values) {
        expect(FaseRastreo.desde(fase.valor), fase);
      }
      expect(() => FaseRastreo.desde('4_otra'), throwsArgumentError);
    });
  });

  group('formatos', () {
    test('el cronómetro va en mm:ss y suma la hora pasada la hora', () {
      expect(formatoCronometro(Duration.zero), '00:00');
      expect(
        formatoCronometro(const Duration(minutes: 7, seconds: 5)),
        '07:05',
      );
      expect(
        formatoCronometro(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatoCronometro(const Duration(seconds: -4)), '00:00');
    });

    test('la hora va en 12 horas con am y pm', () {
      expect(horaCorta(DateTime(2026, 10, 26, 0, 5)), '12:05 am');
      expect(horaCorta(DateTime(2026, 10, 26, 9, 42)), '9:42 am');
      expect(horaCorta(DateTime(2026, 10, 26, 12)), '12:00 pm');
      expect(horaCorta(DateTime(2026, 10, 26, 15, 5)), '3:05 pm');
    });
  });
}

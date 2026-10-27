import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const origen = PuntoGeo(0, 0);

  group('azimutGrados', () {
    test('los cuatro puntos cardinales', () {
      expect(azimutGrados(origen, const PuntoGeo(1, 0)), closeTo(0, 1e-9));
      expect(azimutGrados(origen, const PuntoGeo(0, 1)), closeTo(90, 1e-9));
      expect(azimutGrados(origen, const PuntoGeo(-1, 0)), closeTo(180, 1e-9));
      expect(azimutGrados(origen, const PuntoGeo(0, -1)), closeTo(270, 1e-9));
    });

    test('en diagonal sobre el ecuador da casi 45°', () {
      expect(
        azimutGrados(origen, const PuntoGeo(0.001, 0.001)),
        closeTo(45, 0.01),
      );
      expect(
        azimutGrados(origen, const PuntoGeo(-0.001, -0.001)),
        closeTo(225, 0.01),
      );
    });

    test('en Maracaibo: la URBE queda al oeste-noroeste de la Av. 61', () {
      const av61 = PuntoGeo(10.702096062336127, -71.60399954232982);
      const urbe = PuntoGeo(10.709200993030072, -71.62351346346288);
      // Más al oeste que al norte: entre 270° y 315°.
      expect(azimutGrados(av61, urbe), inInclusiveRange(285, 295));
      // Y de vuelta, el opuesto.
      expect(azimutGrados(urbe, av61), inInclusiveRange(105, 115));
    });

    test('siempre en [0, 360)', () {
      expect(normalizarGrados(-90), 270);
      expect(normalizarGrados(360), 0);
      expect(normalizarGrados(725), 5);
    });
  });

  test('distanciaMetros: un grado de latitud son unos 111,2 km', () {
    expect(distanciaMetros(origen, const PuntoGeo(1, 0)), closeTo(111195, 10));
    expect(distanciaMetros(origen, origen), 0);
    // De la Av. 61 a la URBE en línea recta: unos 2,3 km.
    expect(
      distanciaMetros(
        const PuntoGeo(10.702096062336127, -71.60399954232982),
        const PuntoGeo(10.709200993030072, -71.62351346346288),
      ),
      closeTo(2270, 30),
    );
  });

  group('rumboDeMuestra', () {
    const aqui = PuntoGeo(10.70, -71.61);
    const alNorte = PuntoGeo(10.701, -71.61);

    test('usa el del GPS si viene válido y el teléfono se mueve', () {
      final r = rumboDeMuestra(
        rumboGps: 123,
        velocidadMs: 8,
        actual: alNorte,
        anterior: aqui,
      );
      expect(r?.grados, 123);
      expect(r?.calculado, isFalse);
    });

    test('quieto o con −1, lo calcula con el azimut desde la anterior', () {
      for (final (gps, vel) in const [(0.0, 0.0), (-1.0, 8.0), (null, null)]) {
        final r = rumboDeMuestra(
          rumboGps: gps,
          velocidadMs: vel,
          actual: alNorte,
          anterior: aqui,
        );
        expect(r?.grados, closeTo(0, 1e-6));
        expect(r?.calculado, isTrue);
      }
    });

    test('sin anterior, o a menos de 5 m, no hay rumbo', () {
      expect(
        rumboDeMuestra(rumboGps: -1, velocidadMs: 0, actual: aqui),
        isNull,
      );
      expect(
        rumboDeMuestra(
          rumboGps: -1,
          velocidadMs: 0,
          actual: const PuntoGeo(10.70002, -71.61),
          anterior: aqui,
        ),
        isNull,
      );
    });
  });
}

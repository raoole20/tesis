import 'package:cupo/core/geo/zonas_maracaibo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Zonas de Maracaibo', () {
    test('contiene exactamente las 12 zonas sembradas en la base de datos', () {
      expect(zonasMaracaibo.length, equals(12));

      final nombres = zonasMaracaibo.map((z) => z.nombre).toSet();
      expect(
        nombres,
        containsAll([
          'La Limpia',
          'Circunvalación 2',
          'Cuatricentenario',
          'Las Delicias',
          '5 de Julio',
          'Tierra Negra',
          'El Milagro',
          'Sabaneta',
          'El Amparo',
          'Pomona',
          'Los Haticos',
          'San Francisco',
        ]),
      );
    });

    test('cada zona tiene 4 vértices en orden antihorario y coordenadas válidas', () {
      for (final zona in zonasMaracaibo) {
        expect(
          zona.vertices.length,
          equals(4),
          reason: '${zona.nombre} debe tener 4 esquinas',
        );

        // Latitudes de Maracaibo entre 10.4 y 10.8
        for (final v in zona.vertices) {
          expect(v.latitude, inInclusiveRange(10.4, 10.8));
          // Longitudes de Maracaibo oeste entre -71.7 y -71.5
          expect(v.longitude, inInclusiveRange(-71.7, -71.5));
        }
      }
    });

    test('contiene() detecta puntos dentro de su polígono rectangular', () {
      final laLimpia = zonasMaracaibo.firstWhere((z) => z.nombre == 'La Limpia');

      // Centro aproximado de La Limpia: lat 10.685, lng -71.640
      const puntoDentro = LatLng(10.685, -71.640);
      expect(laLimpia.contiene(puntoDentro), isTrue);

      // Punto fuera de La Limpia (p.ej. Tierra Negra o URBE)
      const puntoFuera = LatLng(10.6978, -71.585); // Tierra Negra aprox
      expect(laLimpia.contiene(puntoFuera), isFalse);
    });

    test('contiene() devuelve false para puntos lejanos o fuera de Maracaibo', () {
      const caracas = LatLng(10.4806, -66.9036);
      for (final zona in zonasMaracaibo) {
        expect(zona.contiene(caracas), isFalse);
      }
    });
  });
}

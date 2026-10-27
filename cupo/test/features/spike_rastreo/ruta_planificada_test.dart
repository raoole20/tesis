import 'dart:convert';
import 'dart:io';

import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/ruta_planificada.dart';
import 'package:flutter_test/flutter_test.dart';

/// Respuestas reales de router.project-osrm.org guardadas el 26-oct-2026:
/// la prueba no toca la red.
Map<String, dynamic> _osrm(String archivo) => jsonDecode(
  File('test/features/spike_rastreo/datos/$archivo').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  test('la ruta por omisión llega a la URBE; la Av. 61 es la salida de '
      'respaldo', () {
    const ruta = RutaDePrueba.porOmision;
    expect(ruta.nombre, 'Prueba: tu ubicación → URBE');
    expect(ruta.etiquetaLlegada, 'URBE');
    expect(ruta.inicio, const PuntoGeo(10.702096062336127, -71.60399954232982));
    expect(
      ruta.llegada,
      const PuntoGeo(10.709200993030072, -71.62351346346288),
    );
    expect(ruta.paradas(idaYVuelta: false), [ruta.inicio, ruta.llegada]);
    expect(ruta.paradas(idaYVuelta: true), [
      ruta.inicio,
      ruta.llegada,
      ruta.inicio,
    ]);
  });

  test('la consulta a OSRM va en lng,lat y pide geometría y pasos', () {
    final url = RutaPlanificada.urlOsrm(
      RutaDePrueba.porOmision.paradas(idaYVuelta: false),
    );
    expect(
      url.toString(),
      'https://router.project-osrm.org/route/v1/driving/'
      '-71.60399954232982,10.702096062336127;'
      '-71.62351346346288,10.709200993030072'
      '?overview=full&geometries=geojson&steps=true',
    );
  });

  group('desdeOsrm', () {
    test('lee la ida: 129 puntos, 5,39 km, 8 min y las calles en orden', () {
      final ruta = RutaPlanificada.desdeOsrm(_osrm('osrm_ida.json'));

      expect(ruta.puntos, hasLength(129));
      expect(ruta.distanciaM, closeTo(5386, 1));
      expect(ruta.duracionS / 60, closeTo(8, 0.1));
      expect(ruta.calles, [
        'Avenida 61',
        'Calle 44 A',
        'Avenida 2',
        'Calle N',
        'Avenida 5',
        'Avenida Circunvalación 2',
        'Avenida Paúl René Moreno Camacho',
      ]);
      // GeoJSON viene en [lng, lat]: el primer punto queda en Maracaibo.
      expect(ruta.puntos.first.lat, closeTo(10.70, 0.01));
      expect(ruta.puntos.first.lng, closeTo(-71.60, 0.01));
      expect(ruta.puntos.last.lat, closeTo(10.709, 0.001));
    });

    test('la línea mide lo mismo que dice OSRM', () {
      final ruta = RutaPlanificada.desdeOsrm(_osrm('osrm_ida.json'));
      var suma = 0.0;
      for (var i = 1; i < ruta.puntos.length; i++) {
        suma += distanciaMetros(ruta.puntos[i - 1], ruta.puntos[i]);
      }
      expect(suma, closeTo(ruta.distanciaM, ruta.distanciaM * 0.01));
    });

    test('ida y vuelta: el doble de largo y vuelve por otras calles', () {
      final ruta = RutaPlanificada.desdeOsrm(_osrm('osrm_ida_vuelta.json'));
      expect(ruta.distanciaM, closeTo(10720, 1));
      expect(ruta.calles, contains('Avenida Milagro Norte'));
      expect(ruta.puntos.first.lat, closeTo(ruta.puntos.last.lat, 0.001));
    });

    test('rechaza una respuesta sin ruta', () {
      expect(
        () => RutaPlanificada.desdeOsrm({'code': 'NoRoute', 'routes': []}),
        throwsFormatException,
      );
      expect(
        () => RutaPlanificada.desdeOsrm({'code': 'Ok', 'routes': []}),
        throwsFormatException,
      );
    });
  });

  test('ewkt: LINESTRING y POINT en lng lat con SRID', () {
    const ruta = RutaPlanificada(
      puntos: [PuntoGeo(10.7, -71.6), PuntoGeo(10.71, -71.62)],
      distanciaM: 1,
      duracionS: 1,
      calles: [],
    );
    expect(ruta.ewkt, 'SRID=4326;LINESTRING(-71.6 10.7,-71.62 10.71)');
    expect(const PuntoGeo(10.7, -71.6).ewkt, 'SRID=4326;POINT(-71.6 10.7)');
  });
}

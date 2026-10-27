import 'dart:convert';
import 'dart:io';

import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/ruta_planificada.dart';
import 'package:cupo/features/spike_rastreo/domain/seguimiento.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un punto a [norte] y [este] metros de (10.7, −71.6).
PuntoGeo _m(double norte, double este) => PuntoGeo(
  10.7 + norte / 111195,
  -71.6 + este / (111195 * 0.98260), // cos(10,7°)
);

final _t0 = DateTime.utc(2026, 10, 27, 13);
DateTime _t(int s) => _t0.add(Duration(seconds: s));

void main() {
  // Una L: 1 km al norte y luego 1 km al este.
  final ele = [_m(0, 0), _m(1000, 0), _m(1000, 1000)];

  group('proyectarEnLinea', () {
    test('un punto sobre la línea se proyecta sobre sí mismo', () {
      final p = proyectarEnLinea(_m(400, 0), ele);
      expect(p.distanciaALinea, closeTo(0, 0.5));
      expect(p.recorrido, closeTo(400, 1));
      expect(p.segmento, 0);
    });

    test('un punto al lado mide su distancia perpendicular', () {
      final p = proyectarEnLinea(_m(400, 60), ele);
      expect(p.distanciaALinea, closeTo(60, 0.5));
      expect(p.recorrido, closeTo(400, 1));
    });

    test('en el segundo tramo suma el largo del primero', () {
      final p = proyectarEnLinea(_m(1030, 250), ele);
      expect(p.segmento, 1);
      expect(p.distanciaALinea, closeTo(30, 0.5));
      expect(p.recorrido, closeTo(1250, 1));
    });

    test('antes del inicio y después del final se acota a los extremos', () {
      expect(proyectarEnLinea(_m(-200, 0), ele).recorrido, closeTo(0, 0.5));
      expect(proyectarEnLinea(_m(1000, 1300), ele).recorrido, closeTo(2000, 1));
    });

    test('desdeSegmento evita volver a un tramo ya pasado', () {
      // Una ida y vuelta por la misma calle.
      final idaVuelta = [_m(0, 0), _m(1000, 0), _m(0, 0)];
      final aLaIda = proyectarEnLinea(_m(300, 0), idaVuelta);
      final aLaVuelta = proyectarEnLinea(
        _m(300, 0),
        idaVuelta,
        desdeSegmento: 1,
      );
      expect(aLaIda.recorrido, closeTo(300, 1));
      expect(aLaVuelta.recorrido, closeTo(1700, 1));
    });
  });

  test('longitudDeLinea suma los tramos', () {
    expect(longitudDeLinea(ele), closeTo(2000, 1));
    expect(longitudDeLinea(const []), 0);
  });

  group('ReglaDeRecalculo', () {
    test('un salto aislado no dispara nada', () {
      final regla = ReglaDeRecalculo();
      expect(regla.evaluar(desvioM: 200, ahora: _t(0)), isFalse);
      expect(regla.evaluar(desvioM: 10, ahora: _t(5)), isFalse);
      expect(regla.evaluar(desvioM: 200, ahora: _t(10)), isFalse);
      expect(regla.evaluar(desvioM: 10, ahora: _t(15)), isFalse);
    });

    test('a 80 m o menos no cuenta como desvío', () {
      final regla = ReglaDeRecalculo();
      for (var s = 0; s < 60; s += 5) {
        expect(regla.evaluar(desvioM: 80, ahora: _t(s)), isFalse);
      }
    });

    test('tres muestras seguidas fuera disparan el recálculo', () {
      final regla = ReglaDeRecalculo();
      expect(regla.evaluar(desvioM: 100, ahora: _t(0)), isFalse);
      expect(regla.evaluar(desvioM: 100, ahora: _t(5)), isFalse);
      expect(regla.evaluar(desvioM: 100, ahora: _t(10)), isTrue);
      expect(regla.ultimoRecalculo, _t(10));
    });

    test('15 s fuera también disparan, aunque lleguen pocas muestras', () {
      final regla = ReglaDeRecalculo();
      expect(regla.evaluar(desvioM: 100, ahora: _t(0)), isFalse);
      expect(regla.evaluar(desvioM: 100, ahora: _t(15)), isTrue);
    });

    test('nunca dos recálculos con menos de 30 s', () {
      final regla = ReglaDeRecalculo();
      final disparos = <int>[];
      for (var s = 0; s <= 120; s += 5) {
        if (regla.evaluar(desvioM: 300, ahora: _t(s))) disparos.add(s);
      }
      expect(disparos, [10, 40, 70, 100]);
    });
  });

  group('SeguimientoDeRuta', () {
    final destino = _m(1000, 1000);

    test('lo que falta baja a medida que avanza sobre la ruta', () {
      final seguimiento = SeguimientoDeRuta(ruta: ele, destino: destino);
      final restantes = <double>[];
      for (var i = 0; i <= 4; i++) {
        seguimiento.actualizar(_m(i * 250.0, 0), _t(i * 5));
        restantes.add(seguimiento.restanteM!);
      }
      expect(restantes.first, closeTo(2000, 1));
      expect(restantes.last, closeTo(1000, 1));
      for (var i = 1; i < restantes.length; i++) {
        expect(restantes[i], lessThan(restantes[i - 1]));
      }
      expect(seguimiento.desvioM, closeTo(0, 0.5));
    });

    test('un desvío sostenido pide recalcular; la ruta nueva se sigue desde '
        'su inicio', () {
      final seguimiento = SeguimientoDeRuta(ruta: ele, destino: destino);
      final eventos = [
        for (var i = 0; i < 3; i++)
          seguimiento.actualizar(_m(300, 150), _t(i * 5)),
      ];
      expect(eventos.map((e) => e.recalcular), [false, false, true]);

      // La nueva sale de donde está la unidad.
      seguimiento.cambiarRuta([_m(300, 150), _m(1000, 150), destino]);
      seguimiento.actualizar(_m(300, 150), _t(15));
      expect(seguimiento.desvioM, closeTo(0, 0.5));
      expect(seguimiento.restanteM, closeTo(700 + 850, 2));
    });

    test('avisa la llegada una sola vez, a 100 m del destino', () {
      final seguimiento = SeguimientoDeRuta(ruta: ele, destino: destino);
      expect(
        seguimiento.actualizar(_m(1000, 850), _t(0)).acabaDeLlegar,
        isFalse,
      );
      expect(
        seguimiento.actualizar(_m(1000, 920), _t(5)).acabaDeLlegar,
        isTrue,
      );
      expect(seguimiento.llego, isTrue);
      expect(
        seguimiento.actualizar(_m(1000, 980), _t(10)).acabaDeLlegar,
        isFalse,
      );
    });

    test('sin ruta, lo que falta es la línea recta y no hay recálculo', () {
      final seguimiento = SeguimientoDeRuta(ruta: const [], destino: destino);
      final evento = seguimiento.actualizar(_m(0, 1000), _t(0));
      expect(seguimiento.restanteM, closeTo(1000, 1));
      expect(seguimiento.desvioM, isNull);
      expect(evento.recalcular, isFalse);
    });

    test('sobre la ruta real de OSRM, al salir faltan 4,92 km', () {
      final ruta = RutaPlanificada.desdeOsrm(
        jsonDecode(
          File('test/features/spike_rastreo/datos/osrm_ida.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final seguimiento = SeguimientoDeRuta(
        ruta: ruta.puntos,
        destino: RutaDePrueba.porOmision.llegada,
      );
      seguimiento.actualizar(ruta.puntos.first, _t(0));
      expect(seguimiento.restanteM, closeTo(ruta.distanciaM, 30));
      seguimiento.actualizar(ruta.puntos[64], _t(5));
      expect(seguimiento.restanteM, lessThan(ruta.distanciaM));
    });
  });
}

import 'dart:async';
import 'dart:math';

import 'package:cupo/features/spike_rastreo/data/fuente_simulada.dart';
import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/seguimiento.dart';
import 'package:cupo/features/spike_rastreo/domain/simulador.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Un punto a [norte] y [este] metros de (10.7, −71.6).
PuntoGeo _m(double norte, double este) =>
    PuntoGeo(10.7 + norte / 111195, -71.6 + este / (111195 * 0.98260));

void main() {
  // 1 km al norte y 500 m al este.
  final linea = [_m(0, 0), _m(1000, 0), _m(1000, 500)];

  SimuladorDeRecorrido sim({
    double kmh = 36,
    double ruido = 0,
    bool corte = false,
    bool desvio = false,
    int semilla = 1,
  }) => SimuladorDeRecorrido(
    linea: linea,
    velocidadKmh: kmh,
    ruidoM: ruido,
    corte: corte,
    desvio: desvio,
    azar: Random(semilla),
  );

  test('a 36 km/h (10 m/s) recorre 1,5 km en 150 s, una muestra cada 5 s', () {
    final s = sim();
    final muestras = s.muestras();

    expect(s.largoM, closeTo(1500, 1));
    expect(s.duracion.inSeconds, closeTo(150, 1));
    expect(muestras, hasLength(31));
    expect(muestras[1].t - muestras[0].t, const Duration(seconds: 5));
    expect(muestras.first.punto, linea.first);
    // La última, justo en el destino.
    expect(distanciaMetros(muestras.last.punto, linea.last), lessThan(0.5));
  });

  test('avanza sobre la línea a la velocidad pedida', () {
    final muestras = sim().muestras();
    for (var i = 1; i < 20; i++) {
      final avance = distanciaMetros(muestras[i - 1].punto, muestras[i].punto);
      expect(avance, closeTo(50, 1), reason: 'muestra $i');
      expect(
        proyectarEnLinea(muestras[i].punto, linea).distanciaALinea,
        closeTo(0, 0.5),
      );
    }
    expect(muestras.first.velocidadMs, closeTo(10, 1e-9));
    expect(muestras.first.precisionM, 8);
  });

  test('el rumbo es el del tramo: norte y luego este', () {
    final muestras = sim().muestras();
    expect(muestras[5].rumbo, closeTo(0, 0.01)); // a 250 m, hacia el norte
    expect(muestras[25].rumbo, closeTo(90, 0.5)); // a 1250 m, hacia el este
  });

  test('el ruido es determinista con la misma semilla y queda en ±7 m', () {
    final a = sim(ruido: 7, semilla: 42).muestras();
    final b = sim(ruido: 7, semilla: 42).muestras();
    final c = sim(ruido: 7, semilla: 43).muestras();
    expect([for (final m in a) m.punto], [for (final m in b) m.punto]);
    expect(a[10].punto, isNot(c[10].punto));
    for (final m in a) {
      // Hasta 7 m por eje: como mucho ~9,9 m de la línea.
      expect(proyectarEnLinea(m.punto, linea).distanciaALinea, lessThan(10));
    }
  });

  test('el corte salta unos 60 s de muestras a mitad de ruta', () {
    final muestras = sim(corte: true).muestras();
    final perdidas = [
      for (final m in muestras)
        if (m.perdida) m.t.inSeconds,
    ];
    expect(perdidas, hasLength(12)); // 60 s / 5 s
    expect(perdidas.first, closeTo(45, 5)); // 75 s − 30 s
    expect(perdidas.last - perdidas.first, 55);
    expect(muestras.last.perdida, isFalse);
  });

  test('el desvío va por una paralela a 150 m durante 45 s', () {
    final muestras = sim(desvio: true).muestras();
    final lejos = [
      for (final m in muestras)
        if (proyectarEnLinea(m.punto, linea).distanciaALinea > 100)
          m.t.inSeconds,
    ];
    expect(lejos, hasLength(9)); // 45 s / 5 s
    expect(lejos.first, closeTo(45, 5)); // al 30 % de 150 s
    // A la izquierda de la marcha (yendo al norte, hacia el oeste).
    final m = muestras.firstWhere((m) => m.t.inSeconds == lejos.first);
    expect(m.punto.lng, lessThan(linea.first.lng));
  });

  test('la fuente simulada emite al ritmo del multiplicador, con el reloj '
      'simulado, y avisa al llegar', () async {
    final fuente = FuenteSimulada(
      simulador: sim(kmh: 360), // 100 m/s: 15 s simulados, 4 muestras
      multiplicador: 100, // una cada 50 ms reales
      inicio: DateTime.utc(2026, 10, 27, 13),
    );
    final llego = Completer<void>();
    fuente.alLlegar = llego.complete;
    final recibidas = <Position>[];
    final horas = <DateTime>[];
    final sub = fuente
        .posiciones(
          intervalo: const Duration(seconds: 5),
          wakelock: false,
          tituloAviso: '',
          textoAviso: '',
        )
        .listen((p) {
          recibidas.add(p);
          horas.add(fuente.reloj.ahora());
        });

    await llego.future.timeout(const Duration(seconds: 5));
    await sub.cancel();

    expect(recibidas, hasLength(4));
    expect(horas, [
      for (var s = 0; s <= 15; s += 5)
        DateTime.utc(2026, 10, 27, 13).add(Duration(seconds: s)),
    ]);
    expect(recibidas.first.speed, closeTo(100, 1e-9));
    expect(fuente.llego, isTrue);
    // Al llegar, el reloj queda un intervalo después de la última muestra.
    expect(fuente.reloj.ahora(), DateTime.utc(2026, 10, 27, 13, 0, 20));
  });
}

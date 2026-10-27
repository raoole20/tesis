import 'dart:math';

import 'geo.dart';

/// Una posición del recorrido simulado.
class MuestraSimulada {
  const MuestraSimulada({
    required this.t,
    required this.punto,
    required this.rumbo,
    required this.velocidadMs,
    required this.precisionM,
    this.perdida = false,
  });

  /// Tiempo simulado desde la salida.
  final Duration t;
  final PuntoGeo punto;

  /// 0 = norte, en grados.
  final double rumbo;
  final double velocidadMs;
  final double precisionM;

  /// Cae dentro del corte de señal: el GPS «no la entrega».
  final bool perdida;
}

/// Recorre [linea] como lo haría un carro, para ver el spike sin manejar.
///
/// Es Dart puro y determinista con [azar] fijo: una muestra cada [intervalo]
/// de tiempo simulado, a [velocidadKmh] constante, con el rumbo del tramo, un
/// ruido de GPS de hasta ±[ruidoM] en cada eje y precisión [precisionM].
///
/// Dos fallos a propósito, para ver cómo se ven en el resultado:
/// - [corte]: unos 60 s sin señal a mitad de ruta (una brecha en rojo);
/// - [desvio]: 45 s por una calle paralela a [desvioM] (dispara el recálculo
///   de la ruta).
///
/// **Una sesión simulada nunca es evidencia** (docs/producto/spike-rastreo.md).
class SimuladorDeRecorrido {
  SimuladorDeRecorrido({
    required List<PuntoGeo> linea,
    this.velocidadKmh = 30,
    this.intervalo = const Duration(seconds: 5),
    this.ruidoM = 7,
    this.precisionM = 8,
    this.corte = false,
    this.duracionCorte = const Duration(seconds: 60),
    this.desvio = false,
    this.desvioM = 150,
    this.duracionDesvio = const Duration(seconds: 45),
    Random? azar,
  }) : assert(linea.length >= 2, 'Hace falta una línea'),
       assert(velocidadKmh > 0),
       _linea = List.unmodifiable(linea),
       _azar = azar ?? Random() {
    var acumulado = 0.0;
    _acumulado.add(0);
    for (var i = 1; i < _linea.length; i++) {
      acumulado += distanciaMetros(_linea[i - 1], _linea[i]);
      _acumulado.add(acumulado);
    }
  }

  final List<PuntoGeo> _linea;
  final Random _azar;
  final List<double> _acumulado = [];

  final double velocidadKmh;
  final Duration intervalo;
  final double ruidoM;
  final double precisionM;
  final bool corte;
  final Duration duracionCorte;
  final bool desvio;
  final double desvioM;
  final Duration duracionDesvio;

  double get velocidadMs => velocidadKmh / 3.6;

  double get largoM => _acumulado.last;

  /// Lo que tarda en recorrer la línea completa.
  Duration get duracion =>
      Duration(milliseconds: (largoM / velocidadMs * 1000).round());

  /// Todas las muestras, de la salida a la llegada (la última, justo en el
  /// destino y sin ruido).
  List<MuestraSimulada> muestras() {
    final total = duracion;
    final mitad = total ~/ 2;
    final inicioCorte = mitad - duracionCorte ~/ 2;
    final finCorte = inicioCorte + duracionCorte;
    final inicioDesvio = total * 0.3;
    final finDesvio = inicioDesvio + duracionDesvio;

    final lista = <MuestraSimulada>[];
    for (var t = Duration.zero; t < total; t += intervalo) {
      final enDesvio = desvio && t >= inicioDesvio && t < finDesvio;
      lista.add(
        _muestra(
          t,
          ruido: true,
          desplazamiento: enDesvio ? desvioM : 0,
          perdida: corte && t >= inicioCorte && t < finCorte,
        ),
      );
    }
    lista.add(_muestra(total, ruido: false, desplazamiento: 0, perdida: false));
    return lista;
  }

  MuestraSimulada _muestra(
    Duration t, {
    required bool ruido,
    required double desplazamiento,
    required bool perdida,
  }) {
    final d = min(largoM, velocidadMs * t.inMilliseconds / 1000);
    final (punto, rumbo) = _enDistancia(d);
    var p = punto;
    if (desplazamiento != 0) {
      // A la izquierda del sentido de marcha.
      p = _mover(p, rumbo - 90, desplazamiento);
    }
    if (ruido && ruidoM > 0) {
      p = _mover(p, 0, (_azar.nextDouble() * 2 - 1) * ruidoM);
      p = _mover(p, 90, (_azar.nextDouble() * 2 - 1) * ruidoM);
    }
    return MuestraSimulada(
      t: t,
      punto: p,
      rumbo: rumbo,
      velocidadMs: velocidadMs,
      precisionM: precisionM,
      perdida: perdida,
    );
  }

  /// El punto a [d] metros del inicio y el rumbo del tramo donde cae.
  (PuntoGeo, double) _enDistancia(double d) {
    var i = 1;
    while (i < _acumulado.length - 1 && _acumulado[i] < d) {
      i++;
    }
    final a = _linea[i - 1];
    final b = _linea[i];
    final largo = _acumulado[i] - _acumulado[i - 1];
    final f = largo == 0
        ? 0.0
        : ((d - _acumulado[i - 1]) / largo).clamp(0.0, 1.0);
    return (
      PuntoGeo(a.lat + (b.lat - a.lat) * f, a.lng + (b.lng - a.lng) * f),
      azimutGrados(a, b),
    );
  }

  static PuntoGeo _mover(PuntoGeo p, double rumbo, double metros) {
    const radio = 6371008.8;
    final r = rumbo * pi / 180;
    final dLat = metros * cos(r) / radio * 180 / pi;
    final dLng = metros * sin(r) / (radio * cos(p.lat * pi / 180)) * 180 / pi;
    return PuntoGeo(p.lat + dLat, p.lng + dLng);
  }
}

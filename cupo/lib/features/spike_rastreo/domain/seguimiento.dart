import 'dart:math';

import 'geo.dart';

/// Dónde cae un punto sobre una polilínea.
class ProyeccionEnLinea {
  const ProyeccionEnLinea({
    required this.punto,
    required this.segmento,
    required this.distanciaALinea,
    required this.recorrido,
  });

  /// El punto más cercano sobre la línea.
  final PuntoGeo punto;

  /// Índice del segmento (entre `linea[segmento]` y `linea[segmento + 1]`).
  final int segmento;

  /// Qué tan lejos de la línea está el punto original, en metros.
  final double distanciaALinea;

  /// Metros de línea desde su inicio hasta [punto].
  final double recorrido;
}

/// Largo de [linea], en metros.
double longitudDeLinea(List<PuntoGeo> linea) {
  var total = 0.0;
  for (var i = 1; i < linea.length; i++) {
    total += distanciaMetros(linea[i - 1], linea[i]);
  }
  return total;
}

/// Proyecta [p] sobre [linea] (al menos 2 puntos).
///
/// Busca desde el segmento [desdeSegmento] en adelante: en un recorrido la
/// unidad avanza, y así una calle que la ruta pisa dos veces no confunde la
/// proyección con el paso de vuelta. Cada segmento se aplana con una
/// proyección equirectangular local: a escala de ciudad el error es de
/// centímetros.
ProyeccionEnLinea proyectarEnLinea(
  PuntoGeo p,
  List<PuntoGeo> linea, {
  int desdeSegmento = 0,
}) {
  assert(linea.length >= 2, 'La línea necesita al menos dos puntos');
  const radio = 6371008.8;
  final cosLat = cos(p.lat * pi / 180);
  // Metros (x hacia el este, y hacia el norte) relativos a p.
  (double, double) xy(PuntoGeo q) => (
    (q.lng - p.lng) * pi / 180 * radio * cosLat,
    (q.lat - p.lat) * pi / 180 * radio,
  );

  ProyeccionEnLinea? mejor;
  var acumulado = 0.0;
  for (var i = 0; i < linea.length - 1; i++) {
    final a = linea[i];
    final b = linea[i + 1];
    final largo = distanciaMetros(a, b);
    if (i >= desdeSegmento) {
      final (ax, ay) = xy(a);
      final (bx, by) = xy(b);
      final dx = bx - ax;
      final dy = by - ay;
      final l2 = dx * dx + dy * dy;
      // El punto p es el origen: t del pie de la perpendicular, acotado.
      final t = l2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / l2).clamp(0.0, 1.0);
      final cx = ax + t * dx;
      final cy = ay + t * dy;
      final distancia = sqrt(cx * cx + cy * cy);
      // Un tramo posterior gana solo si está claramente más cerca (1 m): en
      // una calle que la ruta pisa dos veces, empatan, y manda el primero.
      if (mejor == null || distancia < mejor.distanciaALinea - 1) {
        mejor = ProyeccionEnLinea(
          punto: PuntoGeo(
            a.lat + (b.lat - a.lat) * t,
            a.lng + (b.lng - a.lng) * t,
          ),
          segmento: i,
          distanciaALinea: distancia,
          recorrido: acumulado + largo * t,
        );
      }
    }
    acumulado += largo;
  }
  // Si desdeSegmento se pasó del final, el último segmento.
  return mejor ?? proyectarEnLinea(p, linea, desdeSegmento: linea.length - 2);
}

/// Cuándo pedir una ruta nueva porque la unidad se salió de la planificada.
///
/// Hace falta estar a más de [umbralM] de la ruta **de forma sostenida**
/// (durante [persistencia] o [muestrasSeguidas] muestras, lo primero que
/// ocurra), y no más de un recálculo cada [intervaloMinimo]: un GPS que
/// salta una vez no dispara nada, y un desvío largo no inunda al ruteador.
class ReglaDeRecalculo {
  ReglaDeRecalculo({
    this.umbralM = 80,
    this.persistencia = const Duration(seconds: 15),
    this.muestrasSeguidas = 3,
    this.intervaloMinimo = const Duration(seconds: 30),
  });

  final double umbralM;
  final Duration persistencia;
  final int muestrasSeguidas;
  final Duration intervaloMinimo;

  DateTime? _fueraDesde;
  int _fuera = 0;
  DateTime? _ultimoRecalculo;

  DateTime? get ultimoRecalculo => _ultimoRecalculo;

  /// Registra una muestra a [desvioM] de la ruta. `true` si toca recalcular
  /// ahora.
  bool evaluar({required double desvioM, required DateTime ahora}) {
    if (desvioM <= umbralM) {
      _fueraDesde = null;
      _fuera = 0;
      return false;
    }
    _fueraDesde ??= ahora;
    _fuera++;
    final sostenido =
        _fuera >= muestrasSeguidas ||
        ahora.difference(_fueraDesde!) >= persistencia;
    final ultimo = _ultimoRecalculo;
    final permitido =
        ultimo == null || ahora.difference(ultimo) >= intervaloMinimo;
    if (!sostenido || !permitido) return false;
    _ultimoRecalculo = ahora;
    _fueraDesde = null;
    _fuera = 0;
    return true;
  }
}

/// Lo que pasó con una posición nueva.
typedef EventoDeSeguimiento = ({bool recalcular, bool acabaDeLlegar});

/// Sigue a la unidad sobre la ruta vigente: cuánto falta hasta [destino],
/// cuánto se desvió, si hay que recalcular y si ya llegó.
///
/// Sin ruta (OSRM no respondió), lo que falta es la distancia en línea recta
/// y no hay desvío ni recálculo.
class SeguimientoDeRuta {
  SeguimientoDeRuta({
    required List<PuntoGeo> ruta,
    required this.destino,
    ReglaDeRecalculo? regla,
    this.radioLlegadaM = 100,
  }) : regla = regla ?? ReglaDeRecalculo() {
    cambiarRuta(ruta);
  }

  final PuntoGeo destino;
  final ReglaDeRecalculo regla;

  /// A cuántos metros del destino se considera que llegó.
  final double radioLlegadaM;

  List<PuntoGeo> _ruta = const [];
  double _largo = 0;
  int _segmento = 0;
  double? _restanteM;
  double? _desvioM;
  bool _llego = false;

  List<PuntoGeo> get ruta => _ruta;

  /// Lo que falta hasta el destino, en metros; `null` antes de la primera
  /// posición.
  double? get restanteM => _restanteM;

  /// Distancia a la ruta vigente; `null` sin ruta.
  double? get desvioM => _desvioM;

  bool get llego => _llego;

  /// Una ruta nueva (recalculada): se sigue desde su inicio.
  void cambiarRuta(List<PuntoGeo> ruta) {
    _ruta = List.unmodifiable(ruta);
    _largo = ruta.length >= 2 ? longitudDeLinea(ruta) : 0;
    _segmento = 0;
  }

  EventoDeSeguimiento actualizar(PuntoGeo p, DateTime ahora) {
    var recalcular = false;
    if (_ruta.length >= 2) {
      final proyeccion = proyectarEnLinea(p, _ruta, desdeSegmento: _segmento);
      _segmento = proyeccion.segmento;
      _desvioM = proyeccion.distanciaALinea;
      // Lo que queda de línea desde la proyección de la unidad.
      _restanteM = max(0, _largo - proyeccion.recorrido);
      recalcular = regla.evaluar(
        desvioM: proyeccion.distanciaALinea,
        ahora: ahora,
      );
    } else {
      _desvioM = null;
      _restanteM = distanciaMetros(p, destino);
    }

    final acabaDeLlegar =
        !_llego && distanciaMetros(p, destino) <= radioLlegadaM;
    if (acabaDeLlegar) _llego = true;
    return (recalcular: recalcular && !_llego, acabaDeLlegar: acabaDeLlegar);
  }
}

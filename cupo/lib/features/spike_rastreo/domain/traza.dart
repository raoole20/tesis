import 'geo.dart';
import 'muestra_rastreo.dart';

/// Una fila de `spike_posiciones` leída para dibujar la traza.
class PuntoTraza {
  const PuntoTraza({
    required this.seq,
    required this.punto,
    required this.capturadaEn,
    required this.estadoApp,
    this.pantallaEncendida,
    this.rumboDeg,
    this.cierre = false,
  });

  factory PuntoTraza.fromMap(Map<String, dynamic> fila) {
    final estado = fila['estado_app'] as String;
    return PuntoTraza(
      seq: fila['seq'] as int,
      punto: PuntoGeo(
        (fila['lat'] as num).toDouble(),
        (fila['lng'] as num).toDouble(),
      ),
      capturadaEn: DateTime.parse(fila['capturada_en'] as String),
      estadoApp: EstadoApp.values.firstWhere(
        (e) => e.valor == estado,
        orElse: () => throw ArgumentError.value(estado, 'estado_app'),
      ),
      pantallaEncendida: fila['pantalla_encendida'] as bool?,
      rumboDeg: (fila['rumbo_deg'] as num?)?.toDouble(),
      cierre: fila['cierre'] as bool? ?? false,
    );
  }

  final int seq;
  final PuntoGeo punto;
  final DateTime capturadaEn;
  final EstadoApp estadoApp;
  final bool? pantallaEncendida;
  final double? rumboDeg;

  /// La marca de «Terminar recorrido»: cierra la ventana, no es una muestra.
  final bool cierre;
}

/// Lo que pasaba con el teléfono en una muestra. El mismo criterio que
/// `spike_reporte_ruta()`.
enum ContextoDeUso { primerPlano, segundoPlano, pantallaApagada }

ContextoDeUso contextoDe(EstadoApp estado, bool? pantallaEncendida) {
  if (pantallaEncendida == false) return ContextoDeUso.pantallaApagada;
  return switch (estado) {
    EstadoApp.resumed || EstadoApp.inactive => ContextoDeUso.primerPlano,
    EstadoApp.paused ||
    EstadoApp.hidden ||
    EstadoApp.detached => ContextoDeUso.segundoPlano,
  };
}

/// El trecho entre dos muestras consecutivas.
class TramoTraza {
  const TramoTraza({
    required this.desde,
    required this.hasta,
    required this.segundos,
    required this.metros,
    required this.esBrecha,
  });

  final PuntoTraza desde;
  final PuntoTraza hasta;
  final double segundos;
  final double metros;

  /// Más de [umbral] sin muestras: el estudiante vería la unidad quieta.
  final bool esBrecha;
}

/// Las muestras de [puntos] (sin la marca de cierre) unidas de a dos, en
/// orden de captura. Un tramo es brecha si dura más que [umbral] **o** si
/// salta más que [umbralMetros]: un salto largo en poco tiempo también es un
/// trecho que nadie vio.
List<TramoTraza> tramosDeTraza(
  List<PuntoTraza> puntos, {
  Duration umbral = const Duration(seconds: 30),
  double umbralMetros = 500,
}) {
  final muestras = [
    for (final p in puntos)
      if (!p.cierre) p,
  ]..sort((a, b) => a.capturadaEn.compareTo(b.capturadaEn));
  return [
    for (var i = 1; i < muestras.length; i++)
      _tramo(muestras[i - 1], muestras[i], umbral, umbralMetros),
  ];
}

TramoTraza _tramo(
  PuntoTraza a,
  PuntoTraza b,
  Duration umbral,
  double umbralMetros,
) {
  final segundos =
      b.capturadaEn.difference(a.capturadaEn).inMilliseconds / 1000;
  final metros = distanciaMetros(a.punto, b.punto);
  return TramoTraza(
    desde: a,
    hasta: b,
    segundos: segundos,
    metros: metros,
    esBrecha: segundos > umbral.inMilliseconds / 1000 || metros > umbralMetros,
  );
}

/// Una línea continua para el mapa: puntos seguidos del mismo tipo.
class TrazoDelMapa {
  const TrazoDelMapa({required this.puntos, required this.esBrecha});

  final List<PuntoGeo> puntos;
  final bool esBrecha;
}

/// Agrupa [tramos] consecutivos del mismo tipo en líneas, para dibujar pocas
/// polilíneas en vez de una por tramo. Cada trazo empieza donde terminó el
/// anterior, así la línea se ve continua.
List<TrazoDelMapa> trazosDelMapa(List<TramoTraza> tramos) {
  final trazos = <TrazoDelMapa>[];
  for (final t in tramos) {
    final ultimo = trazos.isEmpty ? null : trazos.last;
    if (ultimo != null && ultimo.esBrecha == t.esBrecha) {
      ultimo.puntos.add(t.hasta.punto);
    } else {
      trazos.add(
        TrazoDelMapa(
          puntos: [t.desde.punto, t.hasta.punto],
          esBrecha: t.esBrecha,
        ),
      );
    }
  }
  return trazos;
}

/// Una flecha que marca el sentido del recorrido.
class FlechaDeSentido {
  const FlechaDeSentido(this.punto, this.rumbo);

  final PuntoGeo punto;

  /// 0 = norte, en el sentido de las agujas del reloj.
  final double rumbo;
}

/// Una flecha cada [cadaMetros] a lo largo de [linea], apuntando hacia
/// adelante. Sirve para distinguir la ida de la vuelta en la figura.
List<FlechaDeSentido> flechasDeSentido(
  List<PuntoGeo> linea, {
  double cadaMetros = 300,
}) {
  final flechas = <FlechaDeSentido>[];
  var acumulado = 0.0;
  var siguiente = cadaMetros / 2;
  for (var i = 1; i < linea.length; i++) {
    final a = linea[i - 1];
    final b = linea[i];
    final d = distanciaMetros(a, b);
    if (d <= 0) continue;
    while (acumulado + d >= siguiente) {
      final f = (siguiente - acumulado) / d;
      flechas.add(
        FlechaDeSentido(
          PuntoGeo(a.lat + (b.lat - a.lat) * f, a.lng + (b.lng - a.lng) * f),
          azimutGrados(a, b),
        ),
      );
      siguiente += cadaMetros;
    }
    acumulado += d;
  }
  return flechas;
}

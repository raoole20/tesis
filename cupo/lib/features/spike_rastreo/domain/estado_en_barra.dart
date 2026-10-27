import 'muestra_rastreo.dart';
import 'protocolo_rastreo.dart';

/// Pasado este tiempo sin una ubicación nueva, la notificación lo dice.
const Duration umbralSinUbicacion = Duration(seconds: 30);

/// Lo que muestra la notificación en vivo de la prueba (y, en web, el título
/// de la pestaña).
class EstadoEnBarra {
  const EstadoEnBarra({
    required this.titulo,
    required this.texto,
    required this.corto,
    this.progreso,
  });

  final String titulo;
  final String texto;

  /// Versión de una línea para el título de la pestaña: «● 128 · 3,2 km».
  final String corto;

  /// Avance de 0 a 1000; `null` sin barra.
  final int? progreso;

  static const int maximo = 1000;
}

/// Arma la notificación a partir del estado de la prueba. Dart puro: la
/// pantalla la publica, como mucho, una vez cada 5 s.
///
/// - [desdeUltima]: tiempo desde la última muestra; `null` si no hay.
/// - [sinRed]: hay pendientes y el último envío falló.
/// - [avanceFases]: de 0 a 1, cuánto va de la prueba por fases.
EstadoEnBarra estadoEnBarra({
  required ModoPrueba modo,
  required bool simulada,
  required bool buscandoGps,
  required int enviadas,
  required int pendientes,
  required bool sinRed,
  FaseRastreo? fase,
  Duration? desdeUltima,
  double? restanteM,
  double? recorridoM,
  double? avanceFases,
}) {
  final titulo = switch (modo) {
    ModoPrueba.fases => 'Prueba de rastreo en curso',
    ModoPrueba.recorrido when simulada => 'Simulación en curso',
    ModoPrueba.recorrido => 'Recorrido a la URBE en curso',
  };

  if (buscandoGps) {
    return EstadoEnBarra(
      titulo: titulo,
      texto: 'Buscando señal GPS…',
      corto: '○ buscando GPS',
    );
  }

  final sinUbicacion = desdeUltima != null && desdeUltima > umbralSinUbicacion;
  final partes = <String>[
    if (modo == ModoPrueba.fases && fase != null)
      'Fase ${fase.numero} de 3 · ${_accionDe(fase)}',
    if (sinUbicacion) 'Sin ubicación hace ${_hace(desdeUltima)}',
    '$enviadas enviadas',
    if (pendientes > 0 && sinRed)
      '⚠ $pendientes pendientes, sin conexión'
    else
      '$pendientes pendientes',
    if (!sinUbicacion && desdeUltima != null)
      'última hace ${_hace(desdeUltima)}',
    if (modo == ModoPrueba.recorrido && restanteM != null)
      'faltan ${distanciaCorta(restanteM)}',
  ];

  int? progreso;
  if (modo == ModoPrueba.fases && avanceFases != null) {
    progreso = (avanceFases.clamp(0.0, 1.0) * EstadoEnBarra.maximo).round();
  } else if (modo == ModoPrueba.recorrido &&
      restanteM != null &&
      recorridoM != null &&
      recorridoM + restanteM > 0) {
    progreso = (recorridoM / (recorridoM + restanteM) * EstadoEnBarra.maximo)
        .round();
  }

  return EstadoEnBarra(
    titulo: titulo,
    texto: partes.join(' · '),
    corto:
        '${sinUbicacion ? '○' : '●'} '
        '${['$enviadas', if (modo == ModoPrueba.recorrido && restanteM != null) distanciaCorta(restanteM), if (modo == ModoPrueba.fases && fase != null) 'fase ${fase.numero}'].join(' · ')}',
    progreso: progreso,
  );
}

/// La notificación que queda al terminar, descartable: «96 % · PASA».
///
/// [coberturaPct] es la de toda la sesión en el recorrido, y la de la peor
/// fase en la prueba por fases. [pasa] es el veredicto (`null` si quedó
/// parcial).
EstadoEnBarra resumenEnBarra({
  required bool simulada,
  double? coberturaPct,
  bool? pasa,
}) {
  final titulo = simulada ? 'Simulación terminada' : 'Prueba terminada';
  final veredicto = switch (pasa) {
    true => 'PASA',
    false => 'NO PASA',
    null => 'resultado parcial',
  };
  final partes = [
    if (coberturaPct != null) '${_decimal(coberturaPct)} %',
    if (coberturaPct != null || pasa != null) veredicto,
    if (coberturaPct == null && pasa == null) 'Abre Cupo para ver el resultado',
    if (simulada) 'no es evidencia',
  ];
  return EstadoEnBarra(
    titulo: titulo,
    texto: partes.join(' · '),
    corto: '✓ ${partes.first}',
  );
}

/// «3,2 km», «820 m».
String distanciaCorta(double metros) =>
    metros >= 1000 ? '${_decimal(metros / 1000)} km' : '${metros.round()} m';

/// «96», «98,3», «3,2»: sin decimales si es entero; coma decimal.
String _decimal(double v) {
  final redondo = double.parse(v.toStringAsFixed(1));
  return (redondo == redondo.roundToDouble()
          ? redondo.round().toString()
          : redondo.toStringAsFixed(1))
      .replaceAll('.', ',');
}

/// «5 s», «45 s», «3 min».
String _hace(Duration d) =>
    d.inSeconds < 120 ? '${d.inSeconds} s' : '${d.inMinutes} min';

String _accionDe(FaseRastreo fase) => switch (fase) {
  FaseRastreo.primerPlano => 'deja Cupo abierta',
  FaseRastreo.minimizada => 'minimiza la app',
  FaseRastreo.pantallaApagada => 'apaga la pantalla',
};

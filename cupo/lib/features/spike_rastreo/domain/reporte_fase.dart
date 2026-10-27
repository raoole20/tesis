import 'protocolo_rastreo.dart';

/// Criterio de éxito del spike, el mismo que aplica `spike_reporte()` por
/// omisión. Está escrito en `docs/producto/spike-rastreo.md`.
abstract final class CriterioRastreo {
  /// Mínimo de muestras recibidas sobre las esperadas, en porcentaje.
  static const double coberturaMinima = 90;

  /// Mayor silencio aceptable entre dos muestras, en segundos. Con el
  /// estudiante mirando el mapa, más de medio minuto sin moverse ya parece
  /// que la unidad se detuvo.
  static const double brechaMaxima = 30;
}

/// Una fila de `spike_reporte(sesion)`: cómo le fue a una fase.
class ReporteFase {
  const ReporteFase({
    required this.fase,
    required this.completa,
    required this.duracionS,
    required this.esperadas,
    required this.recibidas,
    required this.perdidas,
    required this.tardias,
    required this.estados,
    this.coberturaPct,
    this.brechaMaxS,
    this.brechaP95S,
    this.latenciaMedianaS,
    this.cumple,
  });

  factory ReporteFase.fromMap(Map<String, dynamic> fila) {
    return ReporteFase(
      fase: FaseRastreo.desde(fila['fase'] as String),
      completa: fila['completa'] as bool,
      duracionS: fila['duracion_s'] as int,
      esperadas: fila['esperadas'] as int,
      recibidas: fila['recibidas'] as int,
      coberturaPct: _decimal(fila['cobertura_pct']),
      brechaMaxS: _decimal(fila['brecha_max_s']),
      brechaP95S: _decimal(fila['brecha_p95_s']),
      perdidas: fila['perdidas'] as int,
      tardias: fila['tardias'] as int,
      latenciaMedianaS: _decimal(fila['latencia_mediana_s']),
      estados: fila['estados'] as String,
      cumple: fila['cumple'] as bool?,
    );
  }

  final FaseRastreo fase;

  /// Si la ventana de la fase ya terminó. Mientras no, el resultado es
  /// parcial.
  final bool completa;

  final int duracionS;
  final int esperadas;
  final int recibidas;
  final double? coberturaPct;
  final double? brechaMaxS;
  final double? brechaP95S;

  /// Capturadas que nunca llegaron (huecos de `seq`).
  final int perdidas;

  /// Llegaron, pero esperaron en la cola más de 30 s.
  final int tardias;

  /// Mediana de `recibida_en − capturada_en`. Mezcla latencia y desfase
  /// entre el reloj del teléfono y el del servidor.
  final double? latenciaMedianaS;

  /// Cuántas muestras hubo en cada estado de la app: «paused 118 · …».
  final String estados;

  /// `null` si la fase todavía no tiene muestras esperadas.
  final bool? cumple;

  /// PostgREST manda los `numeric` como número o como texto según el tamaño.
  static double? _decimal(Object? valor) => switch (valor) {
    null => null,
    final num n => n.toDouble(),
    final String s => double.parse(s),
    _ => throw ArgumentError.value(valor, 'valor', 'No es un número'),
  };
}

/// El veredicto de la sesión: `true` si las tres fases están completas y
/// cumplen, `false` si alguna completa no cumple, `null` si todavía falta
/// tiempo para decidir.
bool? veredictoRastreo(List<ReporteFase> fases) {
  if (fases.any((f) => f.completa && f.cumple == false)) return false;
  final todas = FaseRastreo.values.every(
    (fase) => fases.any((f) => f.fase == fase && f.completa),
  );
  if (!todas) return null;
  return fases.every((f) => f.cumple == true);
}

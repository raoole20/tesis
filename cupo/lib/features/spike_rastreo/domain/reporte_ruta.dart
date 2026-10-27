/// Criterio de éxito del recorrido real, el mismo que aplica
/// `spike_reporte_ruta()` por omisión (docs/producto/spike-rastreo.md §13.4).
abstract final class CriterioRuta {
  /// Cobertura mínima en segundo plano y con la pantalla apagada, en %.
  static const double coberturaMinima = 90;

  /// Mayor silencio aceptable, en segundos.
  static const double brechaMaximaS = 30;

  /// Mayor salto aceptable sin muestras, en metros: unas cuatro cuadras.
  static const double brechaMaximaM = 500;

  /// Radio del aviso de proximidad (HU-014).
  static const int radioAvisoM = 1500;

  /// Si el recorrido pasó menos que esto (en % del tiempo) fuera de la vista,
  /// no dice nada sobre el segundo plano.
  static const double fueraDeVistaMinimo = 50;
}

/// La fila de `spike_reporte_ruta(sesion)`.
class ReporteRuta {
  const ReporteRuta({
    required this.completa,
    required this.inicio,
    required this.fin,
    required this.duracionS,
    required this.esperadas,
    required this.recibidas,
    required this.perdidas,
    required this.tardias,
    required this.brechasLargas,
    this.simulada = false,
    this.rutasRecalculadas = 0,
    this.distanciaM,
    this.velocidadMediaKmh,
    this.velocidadMaxGpsKmh,
    this.velocidadMaxTrazaKmh,
    this.coberturaPct,
    this.brechaMaxS,
    this.brechaMaxEn,
    this.brechaMaxM,
    this.brechaP95S,
    this.pctPrimerPlano,
    this.pctSegundoPlano,
    this.pctPantallaApagada,
    this.coberturaPrimerPlano,
    this.coberturaSegundoPlano,
    this.coberturaPantallaApagada,
    this.precisionP50M,
    this.precisionP95M,
    this.latenciaMedianaS,
    this.pctCargando,
    this.bateriaInicioPct,
    this.bateriaFinPct,
    this.rutaPlanificadaM,
    this.desvioMedianaM,
    this.desvioP95M,
    this.desvioMaxM,
    this.pctMuestrasCercaRuta,
    this.pctRutaCubierta,
    this.domRadioM,
    this.domDistanciaMinM,
    this.domEntradaEn,
    this.domEntradaM,
    this.domBrechaPreviaS,
    this.domMuestrasAlrededor,
    this.domAvisoATiempo,
    this.cumple,
  });

  factory ReporteRuta.fromMap(Map<String, dynamic> f) {
    DateTime? hora(String c) =>
        f[c] == null ? null : DateTime.parse(f[c] as String);
    double? d(String c) => _decimal(f[c]);
    int? e(String c) => (f[c] as num?)?.toInt();

    return ReporteRuta(
      simulada: f['simulada'] as bool? ?? false,
      rutasRecalculadas: e('rutas_recalculadas') ?? 0,
      completa: f['completa'] as bool,
      inicio: DateTime.parse(f['inicio'] as String),
      fin: DateTime.parse(f['fin'] as String),
      duracionS: (f['duracion_s'] as num).toInt(),
      distanciaM: d('distancia_m'),
      velocidadMediaKmh: d('velocidad_media_kmh'),
      velocidadMaxGpsKmh: d('velocidad_max_gps_kmh'),
      velocidadMaxTrazaKmh: d('velocidad_max_traza_kmh'),
      esperadas: (f['esperadas'] as num).toInt(),
      recibidas: (f['recibidas'] as num).toInt(),
      coberturaPct: d('cobertura_pct'),
      brechaMaxS: d('brecha_max_s'),
      brechaMaxEn: hora('brecha_max_en'),
      brechaMaxM: d('brecha_max_m'),
      brechaP95S: d('brecha_p95_s'),
      brechasLargas: (f['brechas_largas'] as num).toInt(),
      pctPrimerPlano: d('pct_primer_plano'),
      pctSegundoPlano: d('pct_segundo_plano'),
      pctPantallaApagada: d('pct_pantalla_apagada'),
      coberturaPrimerPlano: d('cobertura_primer_plano'),
      coberturaSegundoPlano: d('cobertura_segundo_plano'),
      coberturaPantallaApagada: d('cobertura_pantalla_apagada'),
      precisionP50M: d('precision_p50_m'),
      precisionP95M: d('precision_p95_m'),
      perdidas: (f['perdidas'] as num).toInt(),
      tardias: (f['tardias'] as num).toInt(),
      latenciaMedianaS: d('latencia_mediana_s'),
      pctCargando: d('pct_cargando'),
      bateriaInicioPct: e('bateria_inicio_pct'),
      bateriaFinPct: e('bateria_fin_pct'),
      rutaPlanificadaM: d('ruta_planificada_m'),
      desvioMedianaM: d('desvio_mediana_m'),
      desvioP95M: d('desvio_p95_m'),
      desvioMaxM: d('desvio_max_m'),
      pctMuestrasCercaRuta: d('pct_muestras_cerca_ruta'),
      pctRutaCubierta: d('pct_ruta_cubierta'),
      domRadioM: e('dom_radio_m'),
      domDistanciaMinM: d('dom_distancia_min_m'),
      domEntradaEn: hora('dom_entrada_en'),
      domEntradaM: d('dom_entrada_m'),
      domBrechaPreviaS: d('dom_brecha_previa_s'),
      domMuestrasAlrededor: e('dom_muestras_alrededor'),
      domAvisoATiempo: f['dom_aviso_a_tiempo'] as bool?,
      cumple: f['cumple'] as bool?,
    );
  }

  /// Sesión simulada: **nunca cuenta como evidencia**.
  final bool simulada;

  /// Cuántas veces se recalculó la ruta por un desvío.
  final int rutasRecalculadas;

  /// Si se tocó «Terminar recorrido». Sin eso el resultado es parcial.
  final bool completa;
  final DateTime inicio;
  final DateTime fin;
  final int duracionS;
  final double? distanciaM;
  final double? velocidadMediaKmh;
  final double? velocidadMaxGpsKmh;

  /// Entre muestras de al menos 3 s: si pasa de ~120 km/h en ciudad, la traza
  /// tiene saltos falsos.
  final double? velocidadMaxTrazaKmh;
  final int esperadas;
  final int recibidas;
  final double? coberturaPct;
  final double? brechaMaxS;
  final DateTime? brechaMaxEn;
  final double? brechaMaxM;
  final double? brechaP95S;

  /// Cuántos silencios pasaron de 30 s.
  final int brechasLargas;
  final double? pctPrimerPlano;
  final double? pctSegundoPlano;
  final double? pctPantallaApagada;
  final double? coberturaPrimerPlano;
  final double? coberturaSegundoPlano;
  final double? coberturaPantallaApagada;
  final double? precisionP50M;
  final double? precisionP95M;
  final int perdidas;
  final int tardias;
  final double? latenciaMedianaS;
  final double? pctCargando;
  final int? bateriaInicioPct;
  final int? bateriaFinPct;
  final double? rutaPlanificadaM;
  final double? desvioMedianaM;
  final double? desvioP95M;
  final double? desvioMaxM;
  final double? pctMuestrasCercaRuta;
  final double? pctRutaCubierta;
  final int? domRadioM;
  final double? domDistanciaMinM;
  final DateTime? domEntradaEn;
  final double? domEntradaM;
  final double? domBrechaPreviaS;
  final int? domMuestrasAlrededor;
  final bool? domAvisoATiempo;

  /// `null` mientras el recorrido no esté terminado.
  final bool? cumple;

  /// % del tiempo con la app fuera de la vista (minimizada o pantalla
  /// apagada).
  double get pctFueraDeVista =>
      (pctSegundoPlano ?? 0) + (pctPantallaApagada ?? 0);

  /// El recorrido pasó casi todo el tiempo con Cupo a la vista: aunque
  /// cumpla, no prueba el segundo plano.
  bool get pocoSegundoPlano =>
      pctFueraDeVista < CriterioRuta.fueraDeVistaMinimo;

  static double? _decimal(Object? valor) => switch (valor) {
    null => null,
    final num n => n.toDouble(),
    final String s => double.parse(s),
    _ => throw ArgumentError.value(valor, 'valor', 'No es un número'),
  };
}

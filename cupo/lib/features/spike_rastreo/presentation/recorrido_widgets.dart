part of 'prueba_rastreo_screen.dart';

/// Alto del mapa dentro de la pantalla de la prueba.
const double _altoMapa = 320;

/// «5,4 km», «820 m».
String _distancia(double? metros) {
  if (metros == null) return '—';
  return metros >= 1000
      ? '${_decimal(metros / 1000)} km'
      : '${metros.round()} m';
}

/// «98,3»: coma decimal, como se escribe en Venezuela.
String _decimal(double? valor, {int decimales = 1}) =>
    valor == null ? '—' : valor.toStringAsFixed(decimales).replaceAll('.', ',');

/// Qué hace un toque sobre el mapa de planificación. La llegada no se toca:
/// es la URBE.
enum _Toque { inicio, domicilio }

/// Antes de salir: la ruta de la ubicación actual a la URBE, sobre el mapa
/// real.
class _PanelPlan extends StatelessWidget {
  const _PanelPlan({
    required this.ruta,
    required this.planificada,
    required this.trazando,
    required this.errorRuta,
    required this.buscandoPartida,
    required this.avisoPartida,
    required this.domicilio,
    required this.toque,
    required this.onToque,
    required this.onTapMapa,
    required this.onReintentar,
    required this.onUsarMiUbicacion,
    required this.onQuitarDomicilio,
  });

  final RutaDePrueba ruta;
  final RutaPlanificada? planificada;
  final bool trazando;
  final String? errorRuta;
  final bool buscandoPartida;
  final String? avisoPartida;
  final PuntoGeo? domicilio;
  final _Toque? toque;
  final ValueChanged<_Toque?> onToque;
  final ValueChanged<PuntoGeo> onTapMapa;
  final VoidCallback onReintentar;
  final VoidCallback onUsarMiUbicacion;
  final VoidCallback onQuitarDomicilio;

  @override
  Widget build(BuildContext context) {
    final planificada = this.planificada;
    final errorRuta = this.errorRuta;
    final domicilio = this.domicilio;
    final avisoPartida = this.avisoPartida;
    // Mientras se busca la ubicación no hay salida: el mapa se queda en la
    // URBE.
    final inicio = buscandoPartida ? null : ruta.inicio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ruta planificada', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          buscandoPartida
              ? 'Buscando tu ubicación…'
              : 'De tu ubicación a la ${ruta.etiquetaLlegada}',
          style: AppTypography.helper,
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: SizedBox(
            height: _altoMapa,
            child: MapaRecorrido(
              // Con cada salida o ruta nueva, el mapa se vuelve a encuadrar
              // en la salida y la URBE.
              key: ValueKey(Object.hash(planificada, inicio)),
              rutaPlanificada: planificada?.puntos,
              inicio: inicio,
              llegada: ruta.llegada,
              domicilio: domicilio,
              radioAvisoM: CriterioRuta.radioAvisoM,
              onTap: toque == null ? null : onTapMapa,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Al tocar el mapa, marcar:', style: AppTypography.helper),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (opcion, texto, icono) in const [
              (_Toque.inicio, 'Salida', LucideIcons.play),
              (_Toque.domicilio, 'Domicilio de prueba', LucideIcons.house),
            ])
              _ChipToque(
                texto: texto,
                icono: icono,
                elegido: toque == opcion,
                onTap: () => onToque(toque == opcion ? null : opcion),
              ),
          ],
        ),
        if (avisoPartida != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Aviso(texto: avisoPartida),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (buscandoPartida)
          Text('Buscando tu ubicación…', style: AppTypography.meta)
        else if (trazando)
          Text('Trazando la ruta por las calles…', style: AppTypography.meta)
        else if (errorRuta != null) ...[
          _Aviso(
            texto:
                '$errorRuta Puedes hacer el recorrido igual: el resultado '
                'saldrá sin la comparación contra la ruta.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CupoLink(label: 'Reintentar', onPressed: onReintentar),
          ),
        ] else if (planificada != null) ...[
          Text(
            '${_distancia(planificada.distanciaM)} · ≈'
            '${(planificada.duracionS / 60).round()} min sin tráfico '
            '(según OSRM)',
            style: AppTypography.metaStrong,
          ),
          if (planificada.calles.isNotEmpty)
            Text(planificada.calles.join(' → '), style: AppTypography.helper),
        ],
        if (!buscandoPartida)
          Align(
            alignment: Alignment.centerLeft,
            child: CupoLink(
              label: 'Salir desde mi ubicación actual',
              onPressed: onUsarMiUbicacion,
            ),
          ),
        if (domicilio != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Domicilio de prueba marcado: se medirá cuándo la unidad '
                  'entra a 1,5 km.',
                  style: AppTypography.helper,
                ),
              ),
              CupoLink(label: 'Quitar', onPressed: onQuitarDomicilio),
            ],
          ),
      ],
    );
  }
}

/// Los controles de la simulación.
class _PanelSimulacion extends StatelessWidget {
  const _PanelSimulacion({
    required this.velocidadKmh,
    required this.multiplicador,
    required this.corte,
    required this.desvio,
    required this.onVelocidad,
    required this.onMultiplicador,
    required this.onCorte,
    required this.onDesvio,
  });

  final double velocidadKmh;
  final int multiplicador;
  final bool corte;
  final bool desvio;
  final ValueChanged<double> onVelocidad;
  final ValueChanged<int> onMultiplicador;
  final VoidCallback onCorte;
  final VoidCallback onDesvio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Simulación', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Text('Velocidad de la unidad', style: AppTypography.helper),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final v in const [20.0, 30.0, 50.0])
              _ChipToque(
                texto: '${v.round()} km/h',
                icono: LucideIcons.car,
                elegido: velocidadKmh == v,
                onTap: () => onVelocidad(v),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Qué tan rápido verla', style: AppTypography.helper),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final m in const [1, 5, 20])
              _ChipToque(
                texto: '×$m',
                icono: LucideIcons.timer,
                elegido: multiplicador == m,
                onTap: () => onMultiplicador(m),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        CupoCheckTile(
          icono: LucideIcons.wifiOff,
          titulo: 'Simular un corte de señal',
          descripcion:
              'Unos 60 s sin muestras a mitad de ruta: la brecha '
              'sale en rojo en el resultado.',
          seleccionado: corte,
          onPressed: onCorte,
        ),
        const SizedBox(height: AppSpacing.xs),
        CupoCheckTile(
          icono: LucideIcons.route,
          titulo: 'Simular un desvío',
          descripcion:
              '45 s por una calle paralela, a 150 m: dispara el '
              'recálculo de la ruta.',
          seleccionado: desvio,
          onPressed: onDesvio,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Aviso(
          texto:
              'Las muestras simuladas van a Supabase marcadas como '
              'simuladas. Sirven para probar la app y el reporte; nunca '
              'cuentan como evidencia.',
        ),
      ],
    );
  }
}

/// Lo que se ve en vivo: cuánto falta, cuánto va, el tiempo y la velocidad.
/// Sin hora estimada de llegada: está fuera del alcance (Cuadro 18).
class _PanelEnVivo extends StatelessWidget {
  const _PanelEnVivo({
    required this.restanteM,
    required this.recorridoM,
    required this.transcurrido,
    required this.velocidadKmh,
  });

  final double? restanteM;
  final double recorridoM;
  final Duration transcurrido;
  final double? velocidadKmh;

  @override
  Widget build(BuildContext context) {
    final restante = restanteM;
    final velocidad = velocidadKmh;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Contador(
                valor: restante == null
                    ? '—'
                    : 'Faltan ${_distancia(restante)}',
                rotulo: 'Hasta la URBE',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Contador(
                valor: _distancia(recorridoM),
                rotulo: 'Recorrido',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _Contador(
                valor: formatoCronometro(transcurrido),
                rotulo: 'Tiempo',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Contador(
                valor: velocidad == null ? '—' : '${velocidad.round()} km/h',
                rotulo: 'Velocidad',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipToque extends StatelessWidget {
  const _ChipToque({
    required this.texto,
    required this.icono,
    required this.elegido,
    required this.onTap,
  });

  final String texto;
  final IconData icono;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tinta = elegido ? AppColors.onPrimary : AppColors.primaryDeep;

    return Semantics(
      button: true,
      selected: elegido,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: elegido ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: elegido ? AppColors.primary : AppColors.border,
              width: AppSizes.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: AppSizes.iconSmall, color: tinta),
              const SizedBox(width: AppSpacing.xxs),
              Text(texto, style: AppTypography.label.copyWith(color: tinta)),
            ],
          ),
        ),
      ),
    );
  }
}

/// El resultado del recorrido: veredicto, mapa (la figura) y los números.
class _ResultadoRecorrido extends StatelessWidget {
  const _ResultadoRecorrido({
    required this.reporte,
    required this.traza,
    required this.planificada,
    required this.ruta,
    required this.domicilio,
    required this.onVerMapa,
    required this.onCopiarGeojson,
  });

  final ReporteRuta reporte;
  final List<PuntoTraza>? traza;
  final RutaPlanificada? planificada;
  final RutaDePrueba ruta;
  final PuntoGeo? domicilio;
  final VoidCallback onVerMapa;
  final VoidCallback onCopiarGeojson;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final traza = this.traza;
    const criterio =
        'Criterio: cobertura ≥ 90 % con Cupo minimizada y con la pantalla '
        'apagada, brecha máxima ≤ 30 s y ≤ 500 m.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.simulada) ...[
          const _Aviso(
            texto:
                'SESIÓN SIMULADA: la produjo el simulador, no un GPS. Sirve '
                'para probar la app, el envío y el reporte; nunca cuenta como '
                'evidencia.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        switch (r.cumple) {
          true => const _Tarjeta(
            fondo: AppColors.successSoft,
            icono: LucideIcons.circleCheck,
            etiqueta: 'RESULTADO DEL RECORRIDO',
            titulo: 'Cumple',
            texto: criterio,
          ),
          false => const _Tarjeta(
            fondo: AppColors.dangerSoft,
            icono: LucideIcons.circleX,
            etiqueta: 'RESULTADO DEL RECORRIDO',
            titulo: 'No cumple',
            texto: criterio,
          ),
          null => const _Tarjeta(
            fondo: AppColors.backgroundAlt,
            icono: LucideIcons.circleDashed,
            etiqueta: 'RESULTADO PARCIAL',
            titulo: 'Recorrido sin terminar',
            texto:
                'Falta la marca de «Terminar recorrido»: el final no cuenta. '
                '$criterio',
          ),
        },
        if (r.pocoSegundoPlano) ...[
          const SizedBox(height: AppSpacing.md),
          _Aviso(
            texto:
                'Solo ${_decimal(r.pctFueraDeVista)} % del recorrido fue con '
                'Cupo fuera de la vista: así no prueba el segundo plano. '
                'Repítelo con Cupo minimizada o la pantalla bloqueada.',
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: SizedBox(
            height: _altoMapa,
            child: traza == null
                ? const ColoredBox(color: AppColors.backgroundAlt)
                : _mapa(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        LeyendaRecorrido(
          conRuta: planificada != null,
          conDomicilio: domicilio != null,
        ),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            CupoLink(
              label: 'Ver mapa a pantalla completa',
              onPressed: onVerMapa,
            ),
            CupoLink(label: 'Copiar GeoJSON', onPressed: onCopiarGeojson),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Seccion(
          titulo: 'Recorrido',
          filas: [
            ('Duración', formatoCronometro(Duration(seconds: r.duracionS))),
            ('Distancia', _distancia(r.distanciaM)),
            (
              'Velocidad',
              'media ${_decimal(r.velocidadMediaKmh)} · máx. GPS '
                  '${_decimal(r.velocidadMaxGpsKmh)} · máx. traza '
                  '${_decimal(r.velocidadMaxTrazaKmh)} km/h',
            ),
          ],
        ),
        _Seccion(
          titulo: 'Cobertura',
          filas: [
            (
              'Total',
              '${_decimal(r.coberturaPct)} % (${r.recibidas} de '
                  '${r.esperadas})',
            ),
            (
              'Minimizada',
              '${_decimal(r.coberturaSegundoPlano)} % · '
                  '${_decimal(r.pctSegundoPlano)} % del tiempo',
            ),
            (
              'Pantalla apagada',
              '${_decimal(r.coberturaPantallaApagada)} % · '
                  '${_decimal(r.pctPantallaApagada)} % del tiempo',
            ),
            (
              'Cupo a la vista',
              '${_decimal(r.coberturaPrimerPlano)} % · '
                  '${_decimal(r.pctPrimerPlano)} % del tiempo',
            ),
          ],
        ),
        _Seccion(
          titulo: 'Brechas',
          filas: [
            (
              'Máxima',
              '${_decimal(r.brechaMaxS)} s · salto máx. '
                  '${_distancia(r.brechaMaxM)}'
                  '${r.brechaMaxEn == null ? '' : ' · ${horaCorta(r.brechaMaxEn!.toLocal())}'}',
            ),
            ('p95', '${_decimal(r.brechaP95S)} s'),
            ('Mayores de 30 s', '${r.brechasLargas}'),
            ('Perdidas · tardías', '${r.perdidas} · ${r.tardias}'),
            ('Latencia mediana', '${_decimal(r.latenciaMedianaS)} s'),
          ],
        ),
        if (r.rutaPlanificadaM != null)
          _Seccion(
            titulo: 'Contra la ruta planificada',
            filas: [
              (
                'Desvío',
                'mediana ${_decimal(r.desvioMedianaM)} · p95 '
                    '${_decimal(r.desvioP95M)} · máx. '
                    '${_decimal(r.desvioMaxM)} m',
              ),
              ('Muestras a ≤ 50 m', '${_decimal(r.pctMuestrasCercaRuta)} %'),
              ('Ruta cubierta', '${_decimal(r.pctRutaCubierta)} %'),
              ('Rutas recalculadas', '${r.rutasRecalculadas}'),
            ],
          ),
        _Seccion(
          titulo: 'Teléfono',
          filas: [
            (
              'Precisión GPS',
              'p50 ${_decimal(r.precisionP50M)} · p95 '
                  '${_decimal(r.precisionP95M)} m',
            ),
            (
              'Batería',
              '${r.bateriaInicioPct ?? '—'} % → ${r.bateriaFinPct ?? '—'} % · '
                  'enchufado ${_decimal(r.pctCargando)} % del tiempo',
            ),
          ],
        ),
        if (r.domRadioM != null)
          _Seccion(
            titulo: 'Domicilio de prueba (aviso a 1,5 km)',
            filas: r.domEntradaEn == null
                ? [
                    (
                      'Entrada al radio',
                      'No entró · lo más cerca: '
                          '${_distancia(r.domDistanciaMinM)}',
                    ),
                  ]
                : [
                    (
                      'Entrada al radio',
                      '${horaCorta(r.domEntradaEn!.toLocal())} a '
                          '${_distancia(r.domEntradaM)}',
                    ),
                    (
                      'Silencio justo antes',
                      '${_decimal(r.domBrechaPreviaS)} s',
                    ),
                    ('Muestras ±60 s', '${r.domMuestrasAlrededor ?? 0}'),
                    ('Aviso a tiempo', r.domAvisoATiempo == true ? 'Sí' : 'No'),
                  ],
          ),
      ],
    );
  }

  MapaRecorrido _mapa() => mapaDelResultado(
    traza: traza ?? const [],
    planificada: planificada,
    ruta: ruta,
    domicilio: domicilio,
  );
}

/// El mapa del resultado: el mismo en la pantalla y a pantalla completa.
MapaRecorrido mapaDelResultado({
  required List<PuntoTraza> traza,
  required RutaPlanificada? planificada,
  required RutaDePrueba ruta,
  required PuntoGeo? domicilio,
}) {
  final tramos = tramosDeTraza(traza);
  return MapaRecorrido(
    rutaPlanificada: planificada?.puntos,
    tramos: tramos,
    inicio: ruta.inicio,
    llegada: ruta.llegada,
    domicilio: domicilio,
    radioAvisoM: domicilio == null ? null : CriterioRuta.radioAvisoM,
    flechas: true,
  );
}

/// Un bloque de etiqueta y valor.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.filas});

  final String titulo;
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border, width: AppSizes.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: AppTypography.metaStrong),
            const SizedBox(height: AppSpacing.xxs),
            for (final (etiqueta, valor) in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(etiqueta, style: AppTypography.helper),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      flex: 3,
                      child: Text(valor, style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

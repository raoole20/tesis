import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/auth_scope.dart';
import '../data/zonas_repository.dart';
import '../domain/turno_del_conductor.dart';
import '../domain/zona.dart';
import 'mapa_ruta_del_dia.dart';

/// «Hoy» — Inicio del conductor (`DestinoAuth.inicioConductor`).
///
/// **Prototipo.** El turno, la nómina, los puestos, las solicitudes y los
/// cobros salen de [TurnoDelConductor.ejemplo]: las tablas de la operación
/// llegan con la Iteración 2. Lo único real es quién entró y sus zonas de
/// trabajo, leídas de `conductor_zonas`.
///
/// El mapa de la ruta de hoy ocupa todo el fondo, y lo demás flota encima:
/// arriba, el saludo; abajo, una hoja que se arrastra con lo que el conductor
/// necesita en el día, en este orden: el turno con el botón para empezar el
/// viaje, las solicitudes pendientes, las paradas como una línea de pasos, la
/// nómina, lo que tiene por cobrar y sus zonas.
///
/// El mapa acompaña a la hoja: tocar un paso lo lleva a esa parada, y con el
/// viaje en curso sigue a la unidad, que avanza a la parada del último
/// pasajero marcado a bordo.
class InicioConductorScreen extends StatefulWidget {
  const InicioConductorScreen({
    super.key,
    this.turno = TurnoDelConductor.ejemplo,
    this.repositorio,
    this.hoy,
  });

  final TurnoDelConductor turno;

  /// Por omisión, el de Supabase. Las pruebas pasan uno falso.
  final ZonasRepository? repositorio;

  /// Por omisión, la fecha del teléfono. Las pruebas la fijan.
  final DateTime? hoy;

  @override
  State<InicioConductorScreen> createState() => _InicioConductorScreenState();
}

enum _EstadoViaje { porSalir, enCurso, terminado }

class _InicioConductorScreenState extends State<InicioConductorScreen> {
  /// Alturas de la hoja, como fracción del alto disponible.
  static const double _hojaMinima = 0.25;
  static const double _hojaInicial = 0.45;
  static const double _hojaMaxima = 0.92;

  /// Lo que tapan el saludo flotante y el botón de debajo, medido en el
  /// lienzo de 390×844.
  static const double _altoEncabezado = 168;

  static const double _zoomParada = 16;

  /// Lo que ocupa la acción fija del viaje sobre el pie de la hoja.
  static const double _altoAccion = AppSizes.button + AppSpacing.md * 3;

  late final ZonasRepository _zonas = widget.repositorio ?? ZonasRepository();
  final _mapa = MapController();

  /// Alto del cuerpo de la pantalla, para calcular qué parte del mapa queda
  /// libre entre el saludo y la hoja.
  double _altoCuerpo = 0;

  _EstadoViaje _viaje = _EstadoViaje.porSalir;
  final Set<String> _aBordo = {};
  List<Zona>? _misZonas;
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  /// Las zonas reales del conductor. Si falla, la sección no se muestra: es
  /// un dato de contexto y no debe trancar el inicio.
  Future<void> _cargarZonas() async {
    try {
      final catalogo = await _zonas.catalogo();
      final mias = await _zonas.misZonas();
      if (!mounted) return;
      setState(() {
        _misZonas = [
          for (final zona in catalogo)
            if (mias.contains(zona.id)) zona,
        ];
      });
    } catch (_) {
      // Sin zonas visibles; el resto del inicio sigue igual.
    }
  }

  /// En qué punto del recorrido va la unidad (ver [MapaRutaDelDia.avance]).
  ///
  /// En el prototipo no hay GPS: con el viaje en curso, la unidad está en la
  /// parada del último pasajero que se montó.
  int? get _avance {
    final paradas = widget.turno.paradas;
    switch (_viaje) {
      case _EstadoViaje.porSalir:
        return null;
      case _EstadoViaje.terminado:
        return paradas.length;
      case _EstadoViaje.enCurso:
        var avance = 0;
        for (final pasajero in widget.turno.pasajeros) {
          if (!_aBordo.contains(pasajero.id)) continue;
          final i = paradas.indexWhere((p) => p.nombre == pasajero.parada);
          if (i > avance) avance = i;
        }
        return avance;
    }
  }

  /// El margen del encuadre: lo que queda visible entre el saludo y la hoja
  /// en su altura inicial.
  EdgeInsets _margen(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.xl,
      MediaQuery.paddingOf(context).top + _altoEncabezado,
      AppSpacing.xl,
      _altoCuerpo * _hojaInicial + AppSpacing.md,
    );
  }

  void _encuadrar(List<LatLng> puntos, {double? maxZoom}) {
    _mapa.fitCamera(
      CameraFit.coordinates(
        coordinates: puntos,
        padding: _margen(context),
        maxZoom: maxZoom,
      ),
    );
  }

  /// Lleva el mapa a donde está la unidad, si ya salió.
  void _seguirUnidad() {
    final unidad = MapaRutaDelDia.posicionDeLaUnidad(widget.turno, _avance);
    if (unidad != null) _encuadrar([unidad], maxZoom: _zoomParada);
  }

  void _avanzarViaje() {
    setState(() {
      _viaje = switch (_viaje) {
        _EstadoViaje.porSalir => _EstadoViaje.enCurso,
        _EstadoViaje.enCurso => _EstadoViaje.terminado,
        _EstadoViaje.terminado => _EstadoViaje.terminado,
      };
    });
    _seguirUnidad();
  }

  void _alternarABordo(PasajeroDelDia pasajero) {
    if (_viaje != _EstadoViaje.enCurso) return;
    if (pasajero.asistencia == AsistenciaHoy.noVa) return;
    setState(() {
      _aBordo.contains(pasajero.id)
          ? _aBordo.remove(pasajero.id)
          : _aBordo.add(pasajero.id);
    });
    _seguirUnidad();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.usuarioDe(context);
    final turno = widget.turno;
    final avance = _avance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, caja) {
          _altoCuerpo = caja.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: MapaRutaDelDia(
                  turno: turno,
                  avance: avance,
                  controlador: _mapa,
                  margen: _margen(context),
                  // El crédito va al pie de la hoja, que taparía el de abajo.
                  atribucion: false,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Saludo(
                        fecha: _fechaLarga(widget.hoy ?? DateTime.now()),
                        nombre: usuario.nombres.isEmpty
                            ? 'conductor'
                            : usuario.nombres,
                        iniciales: _iniciales(
                          usuario.nombres,
                          usuario.apellidos,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: BotonSobreMapa(
                          icono: LucideIcons.scan,
                          mensaje: 'Ver todo el recorrido',
                          onPressed: () => _encuadrar(turno.trazado),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: _hojaInicial,
                minChildSize: _hojaMinima,
                maxChildSize: _hojaMaxima,
                snap: true,
                snapSizes: const [_hojaInicial],
                builder: (context, desplazamiento) =>
                    _hoja(desplazamiento, turno, avance),
              ),
              // La acción del viaje queda fija abajo, por encima de la hoja:
              // es lo único que el conductor no puede tener que buscar.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _AccionViaje(
                  turno: turno,
                  estado: _viaje,
                  aBordo: _aBordo.length,
                  onAvanzar: _avanzarViaje,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _BarraInferior(
        actual: _pestana,
        onCambiar: (i) => setState(() => _pestana = i),
      ),
    );
  }

  Widget _hoja(
    ScrollController desplazamiento,
    TurnoDelConductor turno,
    int? avance,
  ) {
    final misZonas = _misZonas;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        controller: desplazamiento,
        // Por debajo, lo último de la lista no queda tapado por la acción.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          _altoAccion + AppSpacing.md,
        ),
        children: [
          const _Asa(),
          _TarjetaTurno(turno: turno, estado: _viaje),
          if (turno.solicitudesNuevas > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _AvisoSolicitudes(turno: turno),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Ruta de hoy', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(_estadoRuta(turno, avance), style: AppTypography.meta),
          const SizedBox(height: AppSpacing.md),
          PasosDeLaRuta(
            turno: turno,
            avance: avance,
            onParada: (punto) => _encuadrar([punto], maxZoom: _zoomParada),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Nomina(
            turno: turno,
            enCurso: _viaje == _EstadoViaje.enCurso,
            aBordo: _aBordo,
            onTocar: _alternarABordo,
          ),
          const SizedBox(height: AppSpacing.xl),
          _PorCobrar(turno: turno),
          if (misZonas != null && misZonas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _MisZonas(zonas: misZonas),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Vista de ejemplo: el turno, la nómina y los cobros son datos de '
            'prueba hasta que se construyan rutas y turnos.',
            style: AppTypography.helper,
            textAlign: TextAlign.center,
          ),
          Center(
            child: CupoLink(
              label: 'Cerrar sesión',
              onPressed: AuthScope.de(context).repositorio.salir,
            ),
          ),
          Text(
            '© OpenStreetMap contributors',
            style: AppTypography.legal,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _estadoRuta(TurnoDelConductor turno, int? avance) {
    final total = turno.paradas.length;
    if (avance == null) return '$total paradas · llegas ${turno.llegada}';
    if (avance >= total) return 'Llegaste a la ${turno.destino}';
    return 'Vas por la parada ${avance + 1} de $total';
  }

  static String _iniciales(String nombres, String apellidos) {
    final a = nombres.trim();
    final b = apellidos.trim();
    final texto = '${a.isEmpty ? '' : a[0]}${b.isEmpty ? '' : b[0]}';
    return texto.isEmpty ? 'C' : texto.toUpperCase();
  }

  /// «Lunes 12 de octubre». A mano para no depender de inicializar los
  /// datos de idioma de `intl`.
  static String _fechaLarga(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }
}

// ═══════════════════════════════════════════════════════════ secciones ═════

class _Saludo extends StatelessWidget {
  const _Saludo({
    required this.fecha,
    required this.nombre,
    required this.iniciales,
  });

  final String fecha;
  final String nombre;
  final String iniciales;

  @override
  Widget build(BuildContext context) {
    // Tarjeta blanca sobre el mapa, con el mismo borde fino de las demás.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fecha, style: AppTypography.meta),
                const SizedBox(height: AppSpacing.xxs),
                Text('Hola, $nombre', style: AppTypography.title),
              ],
            ),
          ),
          _Avatar(iniciales: iniciales, grande: true),
        ],
      ),
    );
  }
}

class _TarjetaTurno extends StatelessWidget {
  const _TarjetaTurno({required this.turno, required this.estado});

  final TurnoDelConductor turno;
  final _EstadoViaje estado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    // Es lo primero de la hoja: va sin tarjeta, la hoja ya es la
    // superficie.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(turno.nombre.toUpperCase(), style: textos.labelSmall),
            ),
            switch (estado) {
              _EstadoViaje.porSalir => const _Etiqueta(
                texto: 'Por salir',
                tinta: AppColors.primaryDeep,
                fondo: AppColors.primarySoft,
              ),
              _EstadoViaje.enCurso => const _Etiqueta(
                texto: 'En curso',
                tinta: AppColors.success,
                fondo: AppColors.successSoft,
                icono: LucideIcons.navigation,
              ),
              _EstadoViaje.terminado => const _Etiqueta(
                texto: 'Terminado',
                tinta: AppColors.textSecondary,
                fondo: AppColors.backgroundMuted,
                icono: LucideIcons.flag,
              ),
            },
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(turno.salida, style: textos.headlineLarge),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'sales de ${turno.origen}',
                style: AppTypography.meta,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Llegas a la ${turno.destino} a las ${turno.llegada} · '
          '${turno.paradas.length} paradas',
          style: AppTypography.bodySmall,
        ),
        Text(
          '${turno.vehiculo} · ${turno.placa}',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _Puestos(turno: turno),
      ],
    );
  }
}

/// Pie fijo sobre la hoja con la acción del viaje y su estado.
class _AccionViaje extends StatelessWidget {
  const _AccionViaje({
    required this.turno,
    required this.estado,
    required this.aBordo,
    required this.onAvanzar,
  });

  final TurnoDelConductor turno;
  final _EstadoViaje estado;
  final int aBordo;
  final VoidCallback onAvanzar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: switch (estado) {
        _EstadoViaje.porSalir => CupoPrimaryButton(
          label: 'Empezar viaje',
          onPressed: onAvanzar,
        ),
        _EstadoViaje.enCurso => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupoPrimaryButton(label: 'Terminar viaje', onPressed: onAvanzar),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Tus pasajeros ven dónde vienes · $aBordo de '
              '${turno.cuantos(AsistenciaHoy.va)} a bordo',
              style: AppTypography.helper,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        _EstadoViaje.terminado => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            'Viaje terminado: $aBordo pasajeros llegaron a la '
            '${turno.destino}.',
            style: AppTypography.metaStrong,
            textAlign: TextAlign.center,
          ),
        ),
      },
    );
  }
}

/// Barra de ocupación: cuántos puestos del vehículo están tomados.
class _Puestos extends StatelessWidget {
  const _Puestos({required this.turno});

  final TurnoDelConductor turno;

  @override
  Widget build(BuildContext context) {
    final libres = turno.puestosLibres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.users,
              size: AppSizes.iconSmall,
              color: AppColors.primaryDeep,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '${turno.puestosOcupados} de ${turno.puestosTotales} puestos '
                'ocupados',
                style: AppTypography.metaStrong,
              ),
            ),
            Text(
              libres == 1 ? '1 libre' : '$libres libres',
              style: AppTypography.meta,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Un segmento por puesto: se cuenta de un vistazo.
        Row(
          children: [
            for (var i = 0; i < turno.puestosTotales; i++) ...[
              Expanded(
                child: Container(
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: i < turno.puestosOcupados
                        ? AppColors.primary
                        : AppColors.backgroundMuted,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
              if (i < turno.puestosTotales - 1)
                const SizedBox(width: AppSpacing.xxs),
            ],
          ],
        ),
      ],
    );
  }
}

class _AvisoSolicitudes extends StatelessWidget {
  const _AvisoSolicitudes({required this.turno});

  final TurnoDelConductor turno;

  @override
  Widget build(BuildContext context) {
    final n = turno.solicitudesNuevas;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.userPlus,
            size: AppSizes.icon,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n == 1 ? '1 solicitud nueva' : '$n solicitudes nuevas',
                  style: AppTypography.metaStrong,
                ),
                Text(
                  'Estudiantes de ${turno.origen} piden un puesto.',
                  style: AppTypography.helper,
                ),
              ],
            ),
          ),
          CupoLink(label: 'Ver', onPressed: () {}),
        ],
      ),
    );
  }
}

class _Nomina extends StatelessWidget {
  const _Nomina({
    required this.turno,
    required this.enCurso,
    required this.aBordo,
    required this.onTocar,
  });

  final TurnoDelConductor turno;
  final bool enCurso;
  final Set<String> aBordo;
  final ValueChanged<PasajeroDelDia> onTocar;

  @override
  Widget build(BuildContext context) {
    final resumen = [
      '${turno.cuantos(AsistenciaHoy.va)} van',
      '${turno.cuantos(AsistenciaHoy.noVa)} no va',
      '${turno.cuantos(AsistenciaHoy.sinConfirmar)} sin confirmar',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nómina de hoy', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          enCurso ? 'Toca a cada pasajero cuando se monte.' : resumen,
          style: AppTypography.meta,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final pasajero in turno.pasajeros) ...[
                _FilaPasajero(
                  pasajero: pasajero,
                  aBordo: aBordo.contains(pasajero.id),
                  onTap: enCurso ? () => onTocar(pasajero) : null,
                ),
                if (pasajero != turno.pasajeros.last)
                  const Divider(
                    color: AppColors.border,
                    height: AppSizes.border,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaPasajero extends StatelessWidget {
  const _FilaPasajero({
    required this.pasajero,
    required this.aBordo,
    required this.onTap,
  });

  final PasajeroDelDia pasajero;
  final bool aBordo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final noVa = pasajero.asistencia == AsistenciaHoy.noVa;

    // Estados de la regla 7 de CLAUDE.md: confirmado en success, pendiente en
    // warning. «No va» no es un error: va apagado, no en danger.
    final etiqueta = aBordo
        ? const _Etiqueta(
            texto: 'A bordo',
            tinta: AppColors.onPrimary,
            fondo: AppColors.primary,
            icono: LucideIcons.userCheck,
          )
        : switch (pasajero.asistencia) {
            AsistenciaHoy.va => const _Etiqueta(
              texto: 'Va',
              tinta: AppColors.success,
              fondo: AppColors.successSoft,
            ),
            AsistenciaHoy.noVa => const _Etiqueta(
              texto: 'No va',
              tinta: AppColors.textSupport,
              fondo: AppColors.backgroundAlt,
            ),
            AsistenciaHoy.sinConfirmar => const _Etiqueta(
              texto: 'Sin confirmar',
              tinta: AppColors.warning,
              fondo: AppColors.warningSoft,
            ),
          };

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Opacity(
            opacity: noVa ? 0.6 : 1,
            child: Row(
              children: [
                _Avatar(iniciales: pasajero.iniciales),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pasajero.nombre, style: AppTypography.metaStrong),
                      Text(
                        '${pasajero.hora} · ${pasajero.parada}',
                        style: AppTypography.helper,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                etiqueta,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PorCobrar extends StatelessWidget {
  const _PorCobrar({required this.turno});

  final TurnoDelConductor turno;

  @override
  Widget build(BuildContext context) {
    final monto = turno.porCobrar.toStringAsFixed(2).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Por cobrar esta semana', style: AppTypography.meta),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '\$$monto',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${turno.pasajerosConSaldo} pasajeros con saldo · cierras el '
                  'viernes',
                  style: AppTypography.helper,
                ),
              ],
            ),
          ),
          CupoLink(label: 'Ver cuentas', onPressed: () {}),
        ],
      ),
    );
  }
}

class _MisZonas extends StatelessWidget {
  const _MisZonas({required this.zonas});

  final List<Zona> zonas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tus zonas de trabajo', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final zona in zonas)
              _Etiqueta(
                texto: zona.nombre,
                tinta: AppColors.primaryDeep,
                fondo: AppColors.primarySoft,
                icono: LucideIcons.mapPin,
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════ piezas ════════

/// Asa de la hoja: indica que se arrastra.
class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSpacing.xxl,
        height: AppSpacing.xxs,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.border,
          borderRadius: AppRadius.smAll,
        ),
      ),
    );
  }
}

/// Pastilla de estado: texto corto sobre su fondo suave.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.tinta,
    required this.fondo,
    this.icono,
  });

  final String texto;
  final Color tinta;
  final Color fondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final icono = this.icono;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: fondo, borderRadius: AppRadius.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: AppSizes.iconSmall, color: tinta),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(texto, style: AppTypography.label.copyWith(color: tinta)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciales, this.grande = false});

  final String iniciales;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final lado = grande ? AppSizes.iconButton : AppSizes.choiceIconTile;

    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        iniciales,
        style: AppTypography.label.copyWith(color: AppColors.primaryDeep),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.actual, required this.onCambiar});

  final int actual;
  final ValueChanged<int> onCambiar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: actual,
        onTap: onCambiar,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSupport,
        selectedLabelStyle: AppTypography.label,
        unselectedLabelStyle: AppTypography.label.copyWith(
          fontWeight: FontWeight.w500,
        ),
        iconSize: AppSizes.icon,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.sun), label: 'Hoy'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendarDays),
            label: 'Semana',
          ),
          BottomNavigationBarItem(icon: Icon(LucideIcons.bus), label: 'Ruta'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet),
            label: 'Cuentas',
          ),
        ],
      ),
    );
  }
}

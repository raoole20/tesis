import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';
import '../../driver/presentation/mapa_ruta_del_dia.dart' show BotonSobreMapa;
import '../domain/geo.dart';
import '../domain/ruta_planificada.dart';
import '../domain/traza.dart';

LatLng _ll(PuntoGeo p) => LatLng(p.lat, p.lng);

/// Brújula sobre un mapa de flutter_map: una flecha que siempre apunta al
/// norte y gira con el mapa. Al tocarla, el mapa vuelve al norte.
///
/// Va como hijo de [FlutterMap]: lee la cámara con [MapCamera.of] y la mueve
/// con [MapController.of]. Lleva el mismo marco que [BotonSobreMapa]; no se
/// reutiliza ese widget porque gira el icono, y aquel no lo permite.
class BrujulaMapa extends StatelessWidget {
  const BrujulaMapa({super.key});

  @override
  Widget build(BuildContext context) {
    final camara = MapCamera.of(context);
    final controlador = MapController.of(context);

    return Tooltip(
      message: 'Volver al norte',
      child: Semantics(
        button: true,
        label: 'Brújula: volver al norte',
        child: GestureDetector(
          onTap: () => controlador.rotate(0),
          child: Container(
            width: AppSizes.iconButton,
            height: AppSizes.iconButton,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: AppColors.border,
                width: AppSizes.border,
              ),
            ),
            // El mismo giro que flutter_map le aplica al mapa: la flecha, que
            // de fábrica apunta arriba, queda apuntando al norte del mapa.
            child: Transform.rotate(
              key: const ValueKey('brujula-flecha'),
              angle: camara.rotationRad,
              child: const Icon(
                LucideIcons.navigation2,
                size: AppSizes.icon,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El mapa del recorrido: la ruta planificada, la traza real con sus brechas
/// y flechas de sentido, los puntos del plan y, en vivo, la unidad.
///
/// Sirve para planificar (con [onTap]), para seguir el recorrido y como
/// figura del resultado.
class MapaRecorrido extends StatefulWidget {
  const MapaRecorrido({
    super.key,
    this.rutaPlanificada,
    this.tramos,
    this.trazaEnVivo,
    this.inicio,
    this.llegada,
    this.domicilio,
    this.radioAvisoM,
    this.unidad,
    this.rumboUnidad,
    this.flechas = false,
    this.onTap,
    this.controlador,
    this.seguirUnidad = false,
  });

  /// La línea de OSRM, en tono suave por debajo de todo.
  final List<PuntoGeo>? rutaPlanificada;

  /// La traza del resultado, ya partida en tramos (brechas en otro color).
  final List<TramoTraza>? tramos;

  /// Lo capturado durante el recorrido, sin clasificar.
  final List<PuntoGeo>? trazaEnVivo;

  final PuntoGeo? inicio;
  final PuntoGeo? llegada;
  final PuntoGeo? domicilio;

  /// Radio del aviso de proximidad alrededor del [domicilio].
  final int? radioAvisoM;

  /// Dónde está la unidad, como flecha orientada por [rumboUnidad].
  final PuntoGeo? unidad;
  final double? rumboUnidad;

  /// Flechas de sentido sobre la traza, cada 300 m.
  final bool flechas;

  final ValueChanged<PuntoGeo>? onTap;

  /// Por omisión, uno propio. Las pruebas lo pasan para girar el mapa.
  final MapController? controlador;

  /// La cámara sigue a la [unidad] en cada posición nueva. Se apaga sola si
  /// la persona mueve el mapa, y se prende o apaga con su botón.
  final bool seguirUnidad;

  @override
  State<MapaRecorrido> createState() => _MapaRecorridoState();
}

class _MapaRecorridoState extends State<MapaRecorrido> {
  /// La URBE: la cámara arranca ahí si todavía no hay nada que encuadrar.
  static final LatLng _urbe = _ll(RutaDePrueba.porOmision.llegada);

  late final MapController _mapa = widget.controlador ?? MapController();
  late bool _siguiendo = widget.seguirUnidad;

  @override
  void didUpdateWidget(MapaRecorrido anterior) {
    super.didUpdateWidget(anterior);
    final unidad = widget.unidad;
    if (_siguiendo && unidad != null && unidad != anterior.unidad) {
      _mapa.move(_ll(unidad), _mapa.camera.zoom);
    }
  }

  void _alternarSeguir() {
    setState(() => _siguiendo = !_siguiendo);
    final unidad = widget.unidad;
    if (_siguiendo && unidad != null) {
      _mapa.move(_ll(unidad), _mapa.camera.zoom);
    }
  }

  @override
  void dispose() {
    if (widget.controlador == null) _mapa.dispose();
    super.dispose();
  }

  List<LatLng> get _todo => [
    ...?widget.rutaPlanificada?.map(_ll),
    for (final t in widget.tramos ?? const <TramoTraza>[]) ...[
      _ll(t.desde.punto),
      _ll(t.hasta.punto),
    ],
    ...?widget.trazaEnVivo?.map(_ll),
    if (widget.inicio case final p?) _ll(p),
    if (widget.llegada case final p?) _ll(p),
    if (widget.domicilio case final p?) _ll(p),
    if (widget.unidad case final p?) _ll(p),
  ];

  void _encuadrar() {
    if (_siguiendo) setState(() => _siguiendo = false);
    final todo = _todo;
    if (todo.length < 2) return;
    _mapa.fitCamera(
      CameraFit.coordinates(
        coordinates: todo,
        padding: const EdgeInsets.all(AppSpacing.xxl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todo = _todo;
    final ruta = widget.rutaPlanificada;
    final tramos = widget.tramos;
    final enVivo = widget.trazaEnVivo;
    final domicilio = widget.domicilio;
    final radio = widget.radioAvisoM;
    final unidad = widget.unidad;
    final onTap = widget.onTap;

    final lineaReal = tramos != null
        ? [
            if (tramos.isNotEmpty) tramos.first.desde.punto,
            for (final t in tramos) t.hasta.punto,
          ]
        : enVivo ?? const <PuntoGeo>[];

    return FlutterMap(
      mapController: _mapa,
      options: MapOptions(
        initialCenter: todo.length == 1 ? todo.first : _urbe,
        initialZoom: 14,
        initialCameraFit: todo.length >= 2
            ? CameraFit.coordinates(
                coordinates: todo,
                padding: const EdgeInsets.all(AppSpacing.xxl),
              )
            : null,
        // Todos los gestos, girar con dos dedos incluido.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        // Si la persona arrastra el mapa, deja de seguir a la unidad.
        onPositionChanged: (_, conGesto) {
          if (conGesto && _siguiendo) setState(() => _siguiendo = false);
        },
        onTap: onTap == null
            ? null
            : (_, punto) => onTap(PuntoGeo(punto.latitude, punto.longitude)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cupo.app',
          maxZoom: 19,
        ),
        if (domicilio != null && radio != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _ll(domicilio),
                radius: radio.toDouble(),
                useRadiusInMeter: true,
                color: AppColors.warning.withValues(alpha: 0.08),
                borderColor: AppColors.warning.withValues(alpha: 0.7),
                borderStrokeWidth: AppSizes.stepConnector,
              ),
            ],
          ),
        PolylineLayer(
          polylines: [
            if (ruta != null && ruta.length >= 2)
              Polyline(
                points: ruta.map(_ll).toList(),
                color: AppColors.primary.withValues(alpha: 0.35),
                strokeWidth: AppSizes.mapRoute + AppSpacing.xxs,
              ),
            if (tramos != null)
              for (final trazo in trazosDelMapa(tramos))
                Polyline(
                  points: trazo.puntos.map(_ll).toList(),
                  color: trazo.esBrecha
                      ? AppColors.danger
                      : AppColors.primaryDarkest,
                  strokeWidth: trazo.esBrecha
                      ? AppSizes.mapRoute
                      : AppSizes.mapRoute - 1,
                  pattern: trazo.esBrecha
                      ? StrokePattern.dashed(segments: const [12, 8])
                      : const StrokePattern.solid(),
                ),
            if (tramos == null && enVivo != null && enVivo.length >= 2)
              Polyline(
                points: enVivo.map(_ll).toList(),
                color: AppColors.primaryDarkest,
                strokeWidth: AppSizes.mapRoute - 1,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (widget.flechas)
              for (final f in flechasDeSentido(lineaReal))
                Marker(
                  point: _ll(f.punto),
                  width: AppSizes.icon,
                  height: AppSizes.icon,
                  // Gira con el mapa (rotate: false), así que basta el
                  // rumbo geográfico del tramo.
                  child: Transform.rotate(
                    angle: f.rumbo * pi / 180,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDarkest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.chevronUp,
                        size: AppSizes.iconSmall,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            if (widget.inicio case final p?)
              _marcador(p, LucideIcons.play, AppColors.success, 'Inicio'),
            if (widget.llegada case final p?)
              _marcador(
                p,
                LucideIcons.flag,
                AppColors.primaryDarkest,
                'Llegada',
              ),
            if (domicilio != null)
              _marcador(
                domicilio,
                LucideIcons.house,
                AppColors.warning,
                'Domicilio de prueba',
              ),
            if (unidad != null)
              Marker(
                key: const ValueKey('marcador-unidad'),
                point: _ll(unidad),
                width: AppSizes.mapVehicle,
                height: AppSizes.mapVehicle,
                child: _Unidad(rumbo: widget.rumboUnidad),
              ),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrujulaMapa(),
                const SizedBox(height: AppSpacing.xs),
                BotonSobreMapa(
                  icono: LucideIcons.scan,
                  mensaje: 'Ver todo el recorrido',
                  onPressed: _encuadrar,
                ),
                if (widget.seguirUnidad && unidad != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  BotonSobreMapa(
                    icono: _siguiendo
                        ? LucideIcons.locateFixed
                        : LucideIcons.locate,
                    mensaje: _siguiendo
                        ? 'Dejar de seguir la unidad'
                        : 'Seguir la unidad',
                    onPressed: _alternarSeguir,
                  ),
                ],
              ],
            ),
          ),
        ),
        const Align(alignment: Alignment.bottomRight, child: _Atribucion()),
      ],
    );
  }

  Marker _marcador(PuntoGeo p, IconData icono, Color fondo, String nombre) {
    return Marker(
      point: _ll(p),
      width: AppSizes.mapStop,
      height: AppSizes.mapStop,
      // Derechos aunque el mapa gire: son rótulos, no direcciones.
      rotate: true,
      child: Tooltip(
        message: nombre,
        child: Container(
          decoration: BoxDecoration(
            color: fondo,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surface,
              width: AppSizes.mapMarkerBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icono,
            size: AppSizes.iconSmall,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// La unidad: una flecha que apunta hacia donde va. Sin rumbo, un punto.
class _Unidad extends StatelessWidget {
  const _Unidad({required this.rumbo});

  final double? rumbo;

  @override
  Widget build(BuildContext context) {
    final rumbo = this.rumbo;

    return Tooltip(
      message: 'Tu unidad',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: AppSizes.mapMarkerBorder,
          ),
        ),
        alignment: Alignment.center,
        child: rumbo == null
            ? Container(
                width: AppSizes.mapDot,
                height: AppSizes.mapDot,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            // El marcador gira con el mapa, así que basta el rumbo
            // geográfico: 0 apunta al norte del mapa.
            : Transform.rotate(
                key: const ValueKey('unidad-flecha'),
                angle: rumbo * pi / 180,
                child: const Icon(
                  LucideIcons.navigation2,
                  size: AppSizes.icon,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

/// El crédito que exige OpenStreetMap.
class _Atribucion extends StatelessWidget {
  const _Atribucion();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      color: AppColors.surface.withValues(alpha: 0.85),
      child: Text('© OpenStreetMap contributors', style: AppTypography.legal),
    );
  }
}

/// Qué es cada cosa del mapa, para la figura.
class LeyendaRecorrido extends StatelessWidget {
  const LeyendaRecorrido({
    super.key,
    this.conRuta = true,
    this.conDomicilio = false,
  });

  final bool conRuta;
  final bool conDomicilio;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (conRuta)
          _Item(
            muestra: _Linea(color: AppColors.primary.withValues(alpha: 0.35)),
            texto: 'Ruta planificada',
          ),
        const _Item(
          muestra: _Linea(color: AppColors.primaryDarkest),
          texto: 'Traza real',
        ),
        const _Item(
          muestra: _Linea(color: AppColors.danger),
          texto: 'Brecha (> 30 s o > 500 m)',
        ),
        const _Item(
          muestra: _Punto(color: AppColors.success),
          texto: 'Inicio',
        ),
        const _Item(
          muestra: _Punto(color: AppColors.primaryDarkest),
          texto: 'Llegada',
        ),
        if (conDomicilio)
          const _Item(
            muestra: _Punto(color: AppColors.warning),
            texto: 'Domicilio de prueba y radio de 1,5 km',
          ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.muestra, required this.texto});

  final Widget muestra;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        muestra,
        const SizedBox(width: AppSpacing.xxs),
        Flexible(child: Text(texto, style: AppTypography.helper)),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.md,
    height: AppSizes.mapRoute - 1,
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.smAll),
  );
}

class _Punto extends StatelessWidget {
  const _Punto({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.sm,
    height: AppSpacing.sm,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// El mapa del resultado a pantalla completa, para sacarle captura y usarla
/// como figura del Cap. IV.
class MapaRecorridoScreen extends StatelessWidget {
  const MapaRecorridoScreen({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.mapa,
    this.conRuta = true,
    this.conDomicilio = false,
  });

  final String titulo;
  final String subtitulo;
  final MapaRecorrido mapa;
  final bool conRuta;
  final bool conDomicilio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  BotonSobreMapa(
                    icono: LucideIcons.x,
                    mensaje: 'Cerrar',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: AppTypography.titleMedium),
                        Text(subtitulo, style: AppTypography.helper),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: mapa),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LeyendaRecorrido(
                conRuta: conRuta,
                conDomicilio: conDomicilio,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

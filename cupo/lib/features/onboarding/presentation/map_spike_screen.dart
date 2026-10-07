import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/location_service.dart';
import '../../../core/geo/zonas_maracaibo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Pantalla del Spike de Georreferenciación y Mapa Interactivo.
///
/// Demuestra:
/// - Mapa OSM con `flutter_map` centrado en la URBE (Maracaibo).
/// - Polígonos de las 12 zonas de cobertura sobre el mapa.
/// - Botón "Mi ubicación" que solicita permiso GPS y centra el mapa.
/// - Pin de domicilio movible tocando cualquier punto del mapa.
/// - Detección de zona: muestra en qué zona cae el pin colocado.
///
/// **Punto de acceso:** lanzar con `flutter run --dart-define=SPIKE_MAP=true`
/// para saltarse el flujo de autenticación.
class MapSpikeScreen extends StatefulWidget {
  const MapSpikeScreen({super.key});

  @override
  State<MapSpikeScreen> createState() => _MapSpikeScreenState();
}

class _MapSpikeScreenState extends State<MapSpikeScreen> {
  // --- Constantes ---

  /// Centro inicial del mapa: sede URBE, Maracaibo.
  static const LatLng _centroUrbe = LatLng(10.6978, -71.6335);
  static const double _zoomInicial = 13.0;
  static const double _zoomUbicacion = 15.0;

  // --- Controlador del mapa ---
  final _mapController = MapController();

  // --- Estado ---
  LatLng? _pinDomicilio;
  ZonaCobertura? _zonaDetectada;

  LatLng? _miUbicacion;
  bool _cargandoUbicacion = false;

  final _locationService = const LocationService();

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación de domicilio', style: textTheme.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Mapa ──────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centroUrbe,
                initialZoom: _zoomInicial,
                onTap: _onMapTap,
              ),
              children: [
                // Tiles de OpenStreetMap
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cupo.app',
                  // Máximo zoom de tiles de OSM
                  maxZoom: 19,
                ),

                // Zonas de cobertura
                PolygonLayer(polygons: _buildPolygons()),

                // Marcadores
                MarkerLayer(markers: _buildMarkers()),

                // Atribución requerida por la licencia de OSM
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── Panel inferior ────────────────────────────────────────
          _InfoPanel(
            pinDomicilio: _pinDomicilio,
            zonaDetectada: _zonaDetectada,
          ),
        ],
      ),

      // ── Botón de ubicación ────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _cargandoUbicacion ? null : _obtenerMiUbicacion,
        tooltip: 'Mi ubicación',
        backgroundColor: AppColors.primary,
        elevation: 0,
        child: _cargandoUbicacion
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : const Icon(Icons.my_location, color: AppColors.onPrimary),
      ),
    );
  }

  // --------------------------------------------------------------- helpers

  /// Construye la lista de polígonos para la capa del mapa.
  List<Polygon> _buildPolygons() {
    return zonasMaracaibo.map((zona) {
      final esDetectada = _zonaDetectada?.nombre == zona.nombre;
      return Polygon(
        points: zona.vertices,
        // Relleno: más visible si es la zona detectada
        color: esDetectada
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primarySoft.withValues(alpha: 0.45),
        borderColor:
            esDetectada ? AppColors.primaryDeep : AppColors.primary,
        borderStrokeWidth: esDetectada ? 2.5 : 1.5,
        label: zona.nombre,
        labelStyle: AppTypography.manrope(
          size: 10,
          weight: FontWeight.w600,
          color: AppColors.primaryDarkest,
        ),
        labelPlacementCalculator:
            const PolygonLabelPlacementCalculator.centroid(),
      );
    }).toList();
  }

  /// Construye los marcadores activos en el mapa.
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_pinDomicilio != null) {
      markers.add(
        Marker(
          point: _pinDomicilio!,
          width: 44,
          height: 44,
          child: const _PinDomicilio(),
        ),
      );
    }

    if (_miUbicacion != null) {
      markers.add(
        Marker(
          point: _miUbicacion!,
          width: 40,
          height: 40,
          child: const _PinUbicacion(),
        ),
      );
    }

    return markers;
  }

  // -------------------------------------------------------------- callbacks

  void _onMapTap(TapPosition tapPosition, LatLng punto) {
    final zona = _detectarZona(punto);
    setState(() {
      _pinDomicilio = punto;
      _zonaDetectada = zona;
    });
  }

  Future<void> _obtenerMiUbicacion() async {
    setState(() => _cargandoUbicacion = true);

    final resultado = await _locationService.getCurrentPosition();

    if (!mounted) return;

    setState(() => _cargandoUbicacion = false);

    switch (resultado) {
      case LocationSuccess(:final position):
        final punto = LatLng(position.latitude, position.longitude);
        setState(() => _miUbicacion = punto);
        _mapController.move(punto, _zoomUbicacion);

      case LocationServiceDisabled():
        _mostrarSnackBar(
          'El GPS está apagado. Actívalo para continuar.',
          accion: ('Ajustes', _locationService.abrirAjustesUbicacion),
        );

      case LocationPermissionDenied():
        _mostrarSnackBar(
          'Se necesita permiso de ubicación para esta función.',
        );

      case LocationPermissionDeniedForever():
        _mostrarSnackBar(
          'Permiso de ubicación denegado. Habilítalo en Ajustes.',
          accion: ('Ajustes', _locationService.abrirAjustesApp),
        );
    }
  }

  void _mostrarSnackBar(
    String mensaje, {
    (String, Future<void> Function())? accion,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        action: accion != null
            ? SnackBarAction(
                label: accion.$1,
                textColor: AppColors.primarySoft,
                onPressed: accion.$2,
              )
            : null,
      ),
    );
  }

  // ----------------------------------------------------------- geo helpers

  /// Busca la primera zona cuyo bounding-box contiene [punto].
  ///
  /// Para el spike es suficiente porque las zonas son rectángulos.
  /// El Spike 3 real implementará ray-casting para polígonos arbitrarios.
  ZonaCobertura? _detectarZona(LatLng punto) {
    for (final zona in zonasMaracaibo) {
      if (zona.contiene(punto)) return zona;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════ sub-widgets ══════

/// Icono del pin de domicilio (casa).
class _PinDomicilio extends StatelessWidget {
  const _PinDomicilio();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.onPrimary, width: 2),
      ),
      child: const Icon(Icons.home, color: AppColors.onPrimary, size: 22),
    );
  }
}

/// Icono del pin de ubicación GPS actual.
class _PinUbicacion extends StatelessWidget {
  const _PinUbicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.onPrimary, width: 2),
      ),
      child: const Icon(
        Icons.my_location,
        color: AppColors.onPrimary,
        size: 20,
      ),
    );
  }
}

/// Panel informativo inferior: muestra coordenadas y zona del pin.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.pinDomicilio,
    required this.zonaDetectada,
  });

  final LatLng? pinDomicilio;
  final ZonaCobertura? zonaDetectada;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Domicilio', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          if (pinDomicilio == null)
            Text(
              'Toca el mapa para colocar tu pin de domicilio',
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else ...[
            Text(
              '${pinDomicilio!.latitude.toStringAsFixed(5)}, '
              '${pinDomicilio!.longitude.toStringAsFixed(5)}',
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSupport),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ZonaChip(zona: zonaDetectada),
          ],
        ],
      ),
    );
  }
}

/// Chip que muestra la zona detectada o "Fuera de cobertura".
class _ZonaChip extends StatelessWidget {
  const _ZonaChip({required this.zona});

  final ZonaCobertura? zona;

  @override
  Widget build(BuildContext context) {
    final dentroDeZona = zona != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: dentroDeZona ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dentroDeZona ? Icons.check_circle_outline : Icons.info_outline,
            size: 14,
            color: dentroDeZona ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            dentroDeZona
                ? 'Zona: ${zona!.nombre}'
                : 'Fuera de las zonas de cobertura',
            style: AppTypography.manrope(
              size: 13,
              weight: FontWeight.w700,
              color: dentroDeZona ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

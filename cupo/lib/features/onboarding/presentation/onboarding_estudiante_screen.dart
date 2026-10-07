import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geo/location_service.dart';
import '../../../core/geo/zonas_maracaibo.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';

/// Pantalla de Onboarding para estudiantes: selección y confirmación de domicilio.
///
/// Se activa cuando un estudiante con cuenta aprobada aún tiene
/// `onboarding_completo = false` (`DestinoAuth.onboardingEstudiante`).
///
/// Flujo:
/// 1. El estudiante ubica su casa en el mapa tocando o usando el GPS.
/// 2. Se muestra retroalimentación inmediata sobre la zona de cobertura.
/// 3. Al pulsar "Confirmar mi domicilio":
///    - Se guarda el punto espacial WKT `POINT(lng lat)` en `public.estudiantes`.
///    - El trigger en PostgreSQL (`detectar_zona`) asigna automáticamente `zona_id`.
///    - La RPC `completar_onboarding()` cambia `usuarios.onboarding_completo = true`.
///    - `AuthGate` reacciona en vivo y navega a `DestinoAuth.inicioEstudiante`.
class OnboardingEstudianteScreen extends StatefulWidget {
  const OnboardingEstudianteScreen({super.key, this.pinInicial});

  final LatLng? pinInicial;

  @override
  State<OnboardingEstudianteScreen> createState() =>
      _OnboardingEstudianteScreenState();
}

class _OnboardingEstudianteScreenState
    extends State<OnboardingEstudianteScreen> {
  // --- Mapa ---
  static const LatLng _centroUrbe = LatLng(10.6978, -71.6335);
  static const double _zoomInicial = 13.0;
  static const double _zoomUbicacion = 15.0;

  final _mapController = MapController();
  final _locationService = const LocationService();

  // --- Estado ---
  LatLng? _pinDomicilio;
  ZonaCobertura? _zonaDetectada;
  LatLng? _miUbicacion;

  final _direccionController = TextEditingController();

  bool _cargandoUbicacion = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.pinInicial != null) {
      _pinDomicilio = widget.pinInicial;
      _zonaDetectada = _detectarZona(widget.pinInicial!);
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Marca dónde vives', style: textTheme.titleMedium),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => AuthScope.de(context).repositorio.salir(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Error Banner si el guardado falla ──────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CupoErrorBanner(mensaje: _error!),
            ),

          // ── Mapa interactivo ──────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centroUrbe,
                initialZoom: _zoomInicial,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cupo.app',
                  maxZoom: 19,
                ),
                PolygonLayer(polygons: _buildPolygons()),
                MarkerLayer(markers: _buildMarkers()),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tarjeta inferior de confirmación ──────────────────────
          _PanelConfirmacion(
            pinDomicilio: _pinDomicilio,
            zonaDetectada: _zonaDetectada,
            direccionController: _direccionController,
            guardando: _guardando,
            onConfirmar: _pinDomicilio == null ? null : _guardarDomicilio,
          ),
        ],
      ),

      // ── Botón de geolocalización ──────────────────────────────────
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

  List<Polygon> _buildPolygons() {
    return zonasMaracaibo.map((zona) {
      final esDetectada = _zonaDetectada?.nombre == zona.nombre;
      return Polygon(
        points: zona.vertices,
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

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_pinDomicilio != null) {
      markers.add(
        Marker(
          point: _pinDomicilio!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.onPrimary, width: 2),
            ),
            child: const Icon(Icons.home, color: AppColors.onPrimary, size: 22),
          ),
        ),
      );
    }

    if (_miUbicacion != null) {
      markers.add(
        Marker(
          point: _miUbicacion!,
          width: 40,
          height: 40,
          child: Container(
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
          ),
        ),
      );
    }

    return markers;
  }

  // -------------------------------------------------------------- callbacks

  void _onMapTap(TapPosition tapPosition, LatLng punto) {
    setState(() {
      _pinDomicilio = punto;
      _zonaDetectada = _detectarZona(punto);
      _error = null;
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

  Future<void> _guardarDomicilio() async {
    final pin = _pinDomicilio;
    if (pin == null) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final repo = AuthScope.de(context).repositorio;
      await repo.fijarDomicilioYCompletarOnboarding(
        latitud: pin.latitude,
        longitud: pin.longitude,
        direccion: _direccionController.text,
      );

      // Si la llamada fue exitosa, forzamos recarga en memoria por si el
      // Realtime tarda unos instantes.
      if (mounted) {
        await repo.cargarUsuarioActual();
      }
    } on AuthFallo catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _guardando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error al guardar tu domicilio: $e';
          _guardando = false;
        });
      }
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

  ZonaCobertura? _detectarZona(LatLng punto) {
    for (final zona in zonasMaracaibo) {
      if (zona.contiene(punto)) return zona;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════ sub-widgets ══════

class _PanelConfirmacion extends StatelessWidget {
  const _PanelConfirmacion({
    required this.pinDomicilio,
    required this.zonaDetectada,
    required this.direccionController,
    required this.guardando,
    required this.onConfirmar,
  });

  final LatLng? pinDomicilio;
  final ZonaCobertura? zonaDetectada;
  final TextEditingController direccionController;
  final bool guardando;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tu Domicilio',
                  style: textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (pinDomicilio != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${pinDomicilio!.latitude.toStringAsFixed(4)}, '
                  '${pinDomicilio!.longitude.toStringAsFixed(4)}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSupport),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (pinDomicilio == null) ...[
            Text(
              'Toca el mapa para colocar el pin donde vives o usa tu ubicación actual.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            _ZonaChip(zona: zonaDetectada),
            const SizedBox(height: AppSpacing.sm),
            CupoTextInput(
              controller: direccionController,
              hintText: 'Punto de referencia o sector (opcional)',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          CupoPrimaryButton(
            label: 'Confirmar mi domicilio',
            isLoading: guardando,
            onPressed: onConfirmar,
          ),
        ],
      ),
    );
  }
}

class _ZonaChip extends StatelessWidget {
  const _ZonaChip({required this.zona});

  final ZonaCobertura? zona;

  @override
  Widget build(BuildContext context) {
    final dentroDeZona = zona != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: dentroDeZona ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(
            dentroDeZona ? Icons.check_circle_outline : Icons.info_outline,
            size: 16,
            color: dentroDeZona ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              dentroDeZona
                  ? 'Zona detectada: ${zona!.nombre}'
                  : 'Fuera de las zonas de cobertura',
              style: AppTypography.manrope(
                size: 13,
                weight: FontWeight.w700,
                color: dentroDeZona ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

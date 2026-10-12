import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/geo/location_service.dart';
import '../../../core/geo/zonas_maracaibo.dart';
import '../../../theme/theme.dart';

/// La zona provisional que contiene [punto], o `null` si cae fuera de todas.
///
/// Es el cálculo local por caja envolvente de [ZonaCobertura.contiene]. En la
/// base, la zona la asigna el trigger `detectar_zona()` al guardar el pin.
ZonaCobertura? zonaDeCobertura(LatLng punto) {
  for (final zona in zonasMaracaibo) {
    if (zona.contiene(punto)) return zona;
  }
  return null;
}

/// Mapa para marcar la casa: un toque fija el [pin], y el botón de ubicación
/// centra el mapa donde está el teléfono.
///
/// No guarda nada: avisa del pin nuevo por [onPin] y quien lo usa decide qué
/// hacer con él. Pinta las zonas de cobertura y resalta la que contiene el pin.
class MapaDomicilio extends StatefulWidget {
  const MapaDomicilio({super.key, required this.pin, required this.onPin});

  /// Dónde está la casa, si ya se marcó.
  final LatLng? pin;

  final ValueChanged<LatLng> onPin;

  @override
  State<MapaDomicilio> createState() => _MapaDomicilioState();
}

class _MapaDomicilioState extends State<MapaDomicilio> {
  static const LatLng _centroUrbe = LatLng(10.6978, -71.6335);
  static const double _zoomInicial = 13;
  static const double _zoomUbicacion = 16;

  final _mapa = MapController();
  final _ubicacion = const LocationService();

  LatLng? _miUbicacion;
  bool _buscandoUbicacion = false;

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final zona = pin == null ? null : zonaDeCobertura(pin);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCenter: pin ?? _centroUrbe,
            initialZoom: pin == null ? _zoomInicial : _zoomUbicacion,
            onTap: (_, punto) => widget.onPin(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cupo.app',
              maxZoom: 19,
            ),
            PolygonLayer(polygons: _poligonos(zona)),
            MarkerLayer(markers: _marcadores(pin)),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: _BotonUbicacion(
            buscando: _buscandoUbicacion,
            onPressed: _irAMiUbicacion,
          ),
        ),
      ],
    );
  }

  List<Polygon> _poligonos(ZonaCobertura? resaltada) {
    return [
      for (final zona in zonasMaracaibo)
        Polygon(
          points: zona.vertices,
          color: zona == resaltada
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.primarySoft.withValues(alpha: 0.45),
          borderColor: zona == resaltada
              ? AppColors.primaryDeep
              : AppColors.primary,
          borderStrokeWidth: zona == resaltada ? 2.5 : 1.5,
        ),
    ];
  }

  List<Marker> _marcadores(LatLng? pin) {
    final miUbicacion = _miUbicacion;

    return [
      if (miUbicacion != null)
        Marker(
          point: miUbicacion,
          width: AppSizes.mapDot,
          height: AppSizes.mapDot,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: AppSizes.mapMarkerBorder,
              ),
            ),
          ),
        ),
      if (pin != null)
        Marker(
          point: pin,
          width: AppSizes.mapPin,
          height: AppSizes.mapPin,
          child: Semantics(
            label: 'Tu casa',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: AppSizes.mapMarkerBorder,
                ),
              ),
              child: const Icon(
                LucideIcons.house,
                size: AppSizes.icon,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _irAMiUbicacion() async {
    setState(() => _buscandoUbicacion = true);
    final resultado = await _ubicacion.getCurrentPosition();
    if (!mounted) return;
    setState(() => _buscandoUbicacion = false);

    switch (resultado) {
      case LocationSuccess(:final position):
        final punto = LatLng(position.latitude, position.longitude);
        setState(() => _miUbicacion = punto);
        _mapa.move(punto, _zoomUbicacion);

      case LocationServiceDisabled():
        _avisar(
          'El GPS está apagado. Actívalo para usar tu ubicación.',
          accion: ('Ajustes', _ubicacion.abrirAjustesUbicacion),
        );

      case LocationPermissionDenied():
        _avisar('Cupo necesita permiso de ubicación para esto.');

      case LocationPermissionDeniedForever():
        _avisar(
          'El permiso de ubicación está negado. Actívalo en Ajustes.',
          accion: ('Ajustes', _ubicacion.abrirAjustesApp),
        );
    }
  }

  void _avisar(String mensaje, {(String, Future<void> Function())? accion}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        action: accion == null
            ? null
            : SnackBarAction(
                label: accion.$1,
                textColor: AppColors.primarySoft,
                onPressed: accion.$2,
              ),
      ),
    );
  }
}

/// Botón cuadrado que centra el mapa en la ubicación del teléfono.
class _BotonUbicacion extends StatelessWidget {
  const _BotonUbicacion({required this.buscando, required this.onPressed});

  final bool buscando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Usar mi ubicación',
      child: GestureDetector(
        onTap: buscando ? null : onPressed,
        child: Container(
          width: AppSizes.iconButton,
          height: AppSizes.iconButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border, width: AppSizes.border),
          ),
          child: buscando
              ? const SizedBox.square(
                  dimension: AppSizes.icon,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.stepConnector,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  LucideIcons.locateFixed,
                  size: AppSizes.icon,
                  color: AppColors.primaryDeep,
                ),
        ),
      ),
    );
  }
}

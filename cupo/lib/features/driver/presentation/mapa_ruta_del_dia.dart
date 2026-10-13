import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';
import '../domain/turno_del_conductor.dart';

/// El recorrido de hoy sobre el mapa: la línea, las paradas numeradas en
/// orden de recogida, la universidad al final y, con el viaje en curso, la
/// unidad.
///
/// [avance] dice dónde va el viaje:
/// - `null`: todavía no sale; no se dibuja la unidad.
/// - `0` a `paradas.length - 1`: la unidad está en esa parada, y esa y las
///   anteriores se pintan como recogidas.
/// - `paradas.length`: llegó al destino.
///
/// Sin [interactivo] el mapa no se mueve con el dedo: es la vista previa
/// dentro de una lista, donde arrastrar debe desplazar la lista y no el mapa.
class MapaRutaDelDia extends StatelessWidget {
  const MapaRutaDelDia({
    super.key,
    required this.turno,
    this.avance,
    this.interactivo = true,
    this.controlador,
    this.margen = const EdgeInsets.all(AppSpacing.xl),
    this.atribucion = true,
  });

  final TurnoDelConductor turno;
  final int? avance;
  final bool interactivo;
  final MapController? controlador;

  /// Cuánto aire deja el encuadre inicial alrededor del recorrido. Cuando hay
  /// algo flotando encima del mapa, el margen de ese lado lo esquiva.
  final EdgeInsets margen;

  /// Si se pinta el crédito de OpenStreetMap sobre el mapa. Quien lo apague
  /// tiene que mostrarlo en otro lugar visible.
  final bool atribucion;

  /// Dónde dibujar la unidad según [avance], o `null` si no ha salido.
  static LatLng? posicionDeLaUnidad(TurnoDelConductor turno, int? avance) {
    if (avance == null) return null;
    if (avance >= turno.paradas.length) return turno.puntoDestino;
    return turno.paradas[avance].punto;
  }

  @override
  Widget build(BuildContext context) {
    final avance = this.avance;
    final unidad = posicionDeLaUnidad(turno, avance);

    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: turno.trazado,
          padding: margen,
        ),
        interactionOptions: InteractionOptions(
          flags: interactivo
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cupo.app',
          maxZoom: 19,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: turno.trazado,
              color: AppColors.primary,
              strokeWidth: AppSizes.mapRoute,
              borderColor: AppColors.surface,
              borderStrokeWidth: AppSizes.mapMarkerBorder,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: turno.puntoDestino,
              width: AppSizes.mapVehicle,
              height: AppSizes.mapVehicle,
              child: _MarcadorDestino(nombre: turno.destino),
            ),
            for (var i = 0; i < turno.paradas.length; i++)
              Marker(
                point: turno.paradas[i].punto,
                width: AppSizes.mapStop,
                height: AppSizes.mapStop,
                child: MarcadorParada(
                  numero: i + 1,
                  nombre: turno.paradas[i].nombre,
                  recogida: avance != null && i <= avance,
                ),
              ),
            if (unidad != null)
              Marker(
                point: unidad,
                width: AppSizes.mapVehicle,
                height: AppSizes.mapVehicle,
                child: const _MarcadorUnidad(),
              ),
          ],
        ),
        if (interactivo && atribucion)
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
      ],
    );
  }
}

/// Círculo numerado de una parada. Hueco mientras falta pasar por ella,
/// lleno en verde lago cuando ya se recogió.
class MarcadorParada extends StatelessWidget {
  const MarcadorParada({
    super.key,
    required this.numero,
    required this.nombre,
    required this.recogida,
  });

  final int numero;
  final String nombre;
  final bool recogida;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Parada $numero: $nombre',
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: recogida ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: recogida ? AppColors.surface : AppColors.primary,
            width: AppSizes.mapMarkerBorder,
          ),
        ),
        child: Text(
          '$numero',
          style: AppTypography.stepNumber.copyWith(
            color: recogida ? AppColors.onPrimary : AppColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}

class _MarcadorDestino extends StatelessWidget {
  const _MarcadorDestino({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: nombre,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDarkest,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: AppColors.surface,
            width: AppSizes.mapMarkerBorder,
          ),
        ),
        child: const Icon(
          LucideIcons.graduationCap,
          size: AppSizes.icon,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

class _MarcadorUnidad extends StatelessWidget {
  const _MarcadorUnidad();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tu unidad',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.surface,
            width: AppSizes.mapMarkerBorder,
          ),
        ),
        child: const Icon(
          LucideIcons.bus,
          size: AppSizes.icon,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// Las paradas del recorrido como una línea de pasos, y la universidad al
/// final. Las paradas ya recogidas y sus tramos van en verde lago. Tocar un
/// paso avisa por [onParada] con su punto, para llevar el mapa ahí.
class PasosDeLaRuta extends StatelessWidget {
  const PasosDeLaRuta({
    super.key,
    required this.turno,
    required this.avance,
    required this.onParada,
  });

  final TurnoDelConductor turno;

  /// Igual que en [MapaRutaDelDia].
  final int? avance;

  final ValueChanged<LatLng> onParada;

  static String _pasajeros(int n) => n == 1 ? '1 pasajero' : '$n pasajeros';

  @override
  Widget build(BuildContext context) {
    final avance = this.avance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < turno.paradas.length; i++)
          _Paso(
            marcador: MarcadorParada(
              numero: i + 1,
              nombre: turno.paradas[i].nombre,
              recogida: avance != null && i <= avance,
            ),
            titulo: turno.paradas[i].nombre,
            detalle:
                '${turno.paradas[i].hora} · '
                '${_pasajeros(turno.pasajerosDe(turno.paradas[i]).length)}',
            // El tramo hacia el paso siguiente se pinta cuando ya se pasó.
            tramoHecho: avance != null && i < avance,
            ultimo: false,
            onTap: () => onParada(turno.paradas[i].punto),
          ),
        _Paso(
          marcador: _MarcadorDestino(nombre: turno.destino),
          titulo: turno.destino,
          detalle: 'Llegada ${turno.llegada}',
          tramoHecho: false,
          ultimo: true,
          onTap: () => onParada(turno.puntoDestino),
        ),
      ],
    );
  }
}

/// Un paso de la línea: el marcador a la izquierda, unido al siguiente por
/// un tramo vertical, y el nombre y la hora a la derecha.
class _Paso extends StatelessWidget {
  const _Paso({
    required this.marcador,
    required this.titulo,
    required this.detalle,
    required this.tramoHecho,
    required this.ultimo,
    required this.onTap,
  });

  final Widget marcador;
  final String titulo;
  final String detalle;
  final bool tramoHecho;
  final bool ultimo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // IntrinsicHeight deja que el tramo se estire al alto del texto.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: AppSizes.mapStop,
              child: Column(
                children: [
                  SizedBox.square(dimension: AppSizes.mapStop, child: marcador),
                  if (!ultimo)
                    Expanded(
                      child: Container(
                        width: AppSizes.stepConnector,
                        color: tramoHecho
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: ultimo ? 0 : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTypography.metaStrong),
                    Text(detalle, style: AppTypography.helper),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón cuadrado flotante sobre un mapa: fondo blanco, borde fino e icono
/// de Lucide. [mensaje] es lo que lee el lector de pantalla y lo que aparece
/// al dejarlo presionado.
class BotonSobreMapa extends StatelessWidget {
  const BotonSobreMapa({
    super.key,
    required this.icono,
    required this.mensaje,
    required this.onPressed,
  });

  final IconData icono;
  final String mensaje;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: mensaje,
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onPressed,
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
            child: Icon(
              icono,
              size: AppSizes.icon,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      ),
    );
  }
}

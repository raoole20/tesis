import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/cuenta/boton_de_cuenta.dart';
import '../domain/turno_del_conductor.dart';
import 'mapa_ruta_del_dia.dart';

/// «Ruta» — el recorrido fijo del turno: el mapa, los datos de la unidad y
/// las paradas en orden. A diferencia de «Hoy», no sigue el viaje: es la
/// ruta tal como está publicada.
///
/// **Prototipo** con [TurnoDelConductor.ejemplo].
class RutaConductorView extends StatefulWidget {
  const RutaConductorView({super.key, required this.turno});

  final TurnoDelConductor turno;

  @override
  State<RutaConductorView> createState() => _RutaConductorViewState();
}

class _RutaConductorViewState extends State<RutaConductorView> {
  static const double _zoomParada = 16;
  final _mapa = MapController();

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turno = widget.turno;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CupoTabHeader(
            titulo: 'Tu ruta',
            detalle: '${turno.origen} → ${turno.destino}',
            accion: const BotonDeCuenta(),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              height: AppSizes.mapPreview,
              child: MapaRutaDelDia(
                turno: turno,
                controlador: _mapa,
                margen: const EdgeInsets.all(AppSpacing.lg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Resumen(turno: turno),
          const SizedBox(height: AppSpacing.xl),
          Text('Paradas', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Toca una parada para verla en el mapa.',
            style: AppTypography.meta,
          ),
          const SizedBox(height: AppSpacing.md),
          PasosDeLaRuta(
            turno: turno,
            avance: null,
            onParada: (punto) => _mapa.move(punto, _zoomParada),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Vista de ejemplo: la ruta es de prueba hasta que se construyan '
            'rutas y turnos.',
            style: AppTypography.helper,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.turno});

  final TurnoDelConductor turno;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Column(
        children: [
          _Dato(
            icono: LucideIcons.clock,
            texto:
                '${turno.nombre}: sales ${turno.salida}, llegas '
                '${turno.llegada}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _Dato(
            icono: LucideIcons.bus,
            texto: '${turno.vehiculo} · ${turno.placa}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _Dato(
            icono: LucideIcons.users,
            texto:
                '${turno.puestosOcupados} de ${turno.puestosTotales} puestos '
                'ocupados · ${turno.paradas.length} paradas',
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: AppSizes.iconSmall, color: AppColors.primaryDeep),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(texto, style: AppTypography.bodySmall)),
      ],
    );
  }
}

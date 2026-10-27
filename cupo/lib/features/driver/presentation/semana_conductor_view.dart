import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/cuenta/boton_de_cuenta.dart';
import '../domain/semana_del_conductor.dart';
import '../domain/turno_del_conductor.dart';

/// «Semana» — los días de servicio y cómo viene la asistencia de cada uno.
///
/// **Prototipo** con [SemanaDelConductor.ejemplo]. Tocar el día de hoy lleva
/// a la pestaña «Hoy» por [onVerHoy].
class SemanaConductorView extends StatelessWidget {
  const SemanaConductorView({
    super.key,
    required this.turno,
    this.semana = SemanaDelConductor.ejemplo,
    required this.onVerHoy,
  });

  final TurnoDelConductor turno;
  final SemanaDelConductor semana;
  final VoidCallback onVerHoy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CupoTabHeader(
            titulo: 'Tu semana',
            detalle: semana.rango,
            accion: const BotonDeCuenta(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${turno.nombre} · sales ${turno.salida} de ${turno.origen}',
            style: AppTypography.meta,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final dia in semana.dias) ...[
            _TarjetaDia(dia: dia, onTap: dia.esHoy ? onVerHoy : null),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Los estudiantes confirman hasta la noche anterior. Vista de '
            'ejemplo hasta que se construyan turnos y asistencias.',
            style: AppTypography.helper,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarjetaDia extends StatelessWidget {
  const _TarjetaDia({required this.dia, required this.onTap});

  final DiaDeServicio dia;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(
          color: dia.esHoy ? AppColors.primary : AppColors.border,
          width: AppSizes.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dia.dia} ${dia.fecha}',
                      style: AppTypography.bodyStrong,
                    ),
                  ),
                  if (dia.esHoy)
                    const CupoStatusChip.marca(
                      texto: 'Hoy',
                      icono: LucideIcons.sun,
                    )
                  else if (dia.sinConfirmar > 0)
                    CupoStatusChip.pendiente(
                      texto: '${dia.sinConfirmar} sin confirmar',
                    )
                  else
                    const CupoStatusChip.exito(texto: 'Todos confirmaron'),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _BarraAsistencia(dia: dia),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${dia.van} van · ${dia.sinConfirmar} sin confirmar · '
                '${dia.noVan} no ${dia.noVan == 1 ? 'va' : 'van'}',
                style: AppTypography.meta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una barra partida en los que van, los que no han dicho y los que no van.
class _BarraAsistencia extends StatelessWidget {
  const _BarraAsistencia({required this.dia});

  final DiaDeServicio dia;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: SizedBox(
        height: AppSpacing.xs,
        child: Row(
          children: [
            if (dia.van > 0)
              Expanded(
                flex: dia.van,
                child: const ColoredBox(color: AppColors.success),
              ),
            if (dia.sinConfirmar > 0)
              Expanded(
                flex: dia.sinConfirmar,
                child: const ColoredBox(color: AppColors.warning),
              ),
            if (dia.noVan > 0)
              Expanded(
                flex: dia.noVan,
                child: const ColoredBox(color: AppColors.border),
              ),
          ],
        ),
      ),
    );
  }
}

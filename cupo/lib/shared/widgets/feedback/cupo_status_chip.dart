import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Etiqueta corta de estado: «Hoy», «Pendiente», «Pagado».
///
/// Los colores siguen la regla de estados: confirmado → `success` sobre
/// `successSoft`; pendiente → `warning` sobre `warningSoft`; error →
/// `danger` sobre `dangerSoft`.
class CupoStatusChip extends StatelessWidget {
  const CupoStatusChip({
    super.key,
    required this.texto,
    required this.tinta,
    required this.fondo,
    this.icono,
  });

  const CupoStatusChip.exito({super.key, required this.texto, this.icono})
    : tinta = AppColors.success,
      fondo = AppColors.successSoft;

  const CupoStatusChip.pendiente({super.key, required this.texto, this.icono})
    : tinta = AppColors.warning,
      fondo = AppColors.warningSoft;

  const CupoStatusChip.marca({super.key, required this.texto, this.icono})
    : tinta = AppColors.primaryDeep,
      fondo = AppColors.primarySoft;

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

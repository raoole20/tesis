import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Opción seleccionable de una lista corta: «Soy estudiante» / «Soy conductor».
///
/// La selección se marca con el verde suave de fondo y el borde en verde lago,
/// no con una sombra: la jerarquía de Cupo se expresa con borde y fondo
/// (regla 5 de CLAUDE.md).
class CupoChoiceTile extends StatelessWidget {
  const CupoChoiceTile({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.seleccionado,
    required this.onPressed,
  });

  final String titulo;
  final String descripcion;
  final bool seleccionado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primarySoft : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: seleccionado
                  ? AppTypography.bodyStrong
                  : AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(descripcion, style: AppTypography.helper),
          ],
        ),
      ),
    );
  }
}

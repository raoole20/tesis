import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_focus_ring.dart';

/// Opción seleccionable de una lista corta: «Soy estudiante» / «Soy conductor».
///
/// La selección se marca con el verde suave de fondo, el borde en verde lago y
/// el halo de [CupoFocusRing], no con una sombra: la jerarquía de Cupo se
/// expresa con borde y fondo (regla 5 de CLAUDE.md). El título no cambia de
/// tamaño al seleccionarse, para que la lista no salte.
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
      child: CupoFocusRing(
        visible: seleccionado,
        radius: AppRadius.md,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.primarySoft : AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: seleccionado ? AppColors.primary : AppColors.border,
              width: AppSizes.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(descripcion, style: AppTypography.helper),
            ],
          ),
        ),
      ),
    );
  }
}

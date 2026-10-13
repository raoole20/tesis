import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';
import 'cupo_focus_ring.dart';

/// Fila seleccionable de una lista: «Las Delicias · Maracaibo».
///
/// Es la hermana horizontal de [CupoChoiceTile]: aquella va de a dos en una
/// fila y sirve para elegir entre pocas cosas; esta se apila y sirve para
/// listas más largas, de selección simple o múltiple.
///
/// A la izquierda, el [icono] opcional en su mosaico; en el centro, el título
/// y la descripción; a la derecha, un círculo que se llena con un visto al
/// seleccionarse. La selección se marca igual que en [CupoChoiceTile]: fondo
/// verde suave, borde verde lago y el halo de [CupoFocusRing], sin sombras
/// (regla 5 de CLAUDE.md).
class CupoCheckTile extends StatelessWidget {
  const CupoCheckTile({
    super.key,
    this.icono,
    required this.titulo,
    this.descripcion,
    required this.seleccionado,
    required this.onPressed,
  });

  /// Un icono de `LucideIcons`. Si es `null`, la fila no lleva mosaico.
  final IconData? icono;

  final String titulo;

  /// Segunda línea, más tenue. Si es `null`, no ocupa espacio.
  final String? descripcion;

  final bool seleccionado;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final icono = this.icono;
    final descripcion = this.descripcion;

    return Semantics(
      button: true,
      selected: seleccionado,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: CupoFocusRing(
          visible: seleccionado,
          radius: AppRadius.md,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: seleccionado ? AppColors.primarySoft : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: seleccionado ? AppColors.primary : AppColors.border,
                width: AppSizes.border,
              ),
            ),
            child: Row(
              children: [
                if (icono != null) ...[
                  _Mosaico(icono: icono, seleccionado: seleccionado),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: AppTypography.bodyStrong),
                      if (descripcion != null)
                        Text(descripcion, style: AppTypography.helper),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  seleccionado ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: AppSizes.icon,
                  color: seleccionado ? AppColors.primary : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El icono de la fila en un mosaico cuadrado, como en [CupoChoiceTile].
class _Mosaico extends StatelessWidget {
  const _Mosaico({required this.icono, required this.seleccionado});

  final IconData icono;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.choiceIconTile,
      height: AppSizes.choiceIconTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.primary : AppColors.backgroundMuted,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(
        icono,
        size: AppSizes.icon,
        color: seleccionado ? AppColors.onPrimary : AppColors.primaryDeep,
      ),
    );
  }
}

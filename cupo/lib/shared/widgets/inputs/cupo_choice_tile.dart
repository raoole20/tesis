import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';
import 'cupo_focus_ring.dart';

/// Opción seleccionable de una lista corta: «Soy estudiante» / «Soy conductor».
///
/// Es un cuadrado perfecto —el alto lo fija el ancho que le den—, pensado para
/// ir de a dos en una fila. Arriba, el [icono] de Lucide en su mosaico y, al
/// seleccionarse, un visto; abajo, el título y una descripción corta.
///
/// La selección se marca con el verde suave de fondo, el borde en verde lago y
/// el halo de [CupoFocusRing], no con una sombra: la jerarquía de Cupo se
/// expresa con borde y fondo (regla 5 de CLAUDE.md). El título no cambia de
/// tamaño al seleccionarse, para que la fila no salte. Si la letra del sistema
/// es grande, el texto se encoge para caber en vez de desbordar el cuadrado.
class CupoChoiceTile extends StatelessWidget {
  const CupoChoiceTile({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.seleccionado,
    required this.onPressed,
  });

  /// Un icono de `LucideIcons`.
  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool seleccionado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: CupoFocusRing(
          visible: seleccionado,
          radius: AppRadius.md,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MosaicoIcono(icono: icono, seleccionado: seleccionado),
                      const Spacer(),
                      if (seleccionado)
                        const Icon(
                          LucideIcons.circleCheck,
                          size: AppSizes.icon,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, caja) => Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          // El ancho útil fijo hace que el texto parta en
                          // líneas antes de encogerse.
                          child: SizedBox(
                            width: caja.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(titulo, style: AppTypography.bodyStrong),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(descripcion, style: AppTypography.helper),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El icono de la opción en un mosaico cuadrado.
class _MosaicoIcono extends StatelessWidget {
  const _MosaicoIcono({required this.icono, required this.seleccionado});

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

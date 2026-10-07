import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Halo de foco alrededor de un control: un anillo de [AppSizes.focusRing]
/// en [AppColors.primaryRing], dibujado **por fuera** del borde.
///
/// Se pinta con un borde en vez de una sombra. Así no ocupa espacio en el
/// layout, porque el control no se encoge al tomar el foco, y la regla 5 de
/// CLAUDE.md sigue en pie: el halo marca un estado, no una elevación.
///
/// Lo usan los campos de texto, la casilla activa del código y la opción
/// seleccionada.
class CupoFocusRing extends StatelessWidget {
  const CupoFocusRing({
    super.key,
    required this.visible,
    required this.radius,
    required this.child,
  });

  /// Si el halo se ve.
  final bool visible;

  /// Radio de esquina del control que rodea. El del halo es este más
  /// [AppSizes.focusRing], para que el anillo quede concéntrico.
  final double radius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned.fill(
            left: -AppSizes.focusRing,
            top: -AppSizes.focusRing,
            right: -AppSizes.focusRing,
            bottom: -AppSizes.focusRing,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    radius + AppSizes.focusRing,
                  ),
                  border: Border.all(
                    color: AppColors.primaryRing,
                    width: AppSizes.focusRing,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

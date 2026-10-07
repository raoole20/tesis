import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Botón circular de retroceso del encabezado.
///
/// El círculo visible mide [AppSizes.backButton] y va relleno de
/// [AppColors.backgroundMuted], sin borde. El área táctil es mayor
/// ([AppSizes.iconButton]) para que sea cómodo de tocar sin agrandar el
/// dibujo; el círculo se pega al borde inicial de esa área para quedar
/// alineado con el contenido de la pantalla.
///
/// Si no se le pasa [onPressed], usa el `Navigator` más cercano.
class CupoBackButton extends StatelessWidget {
  const CupoBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final alTocar = onPressed ?? () => Navigator.of(context).maybePop();

    return Semantics(
      button: true,
      label: 'Volver',
      child: SizedBox.square(
        dimension: AppSizes.iconButton,
        child: GestureDetector(
          onTap: alTocar,
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: AppSizes.backButton,
              child: Material(
                color: AppColors.backgroundMuted,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                // cupo-ignore: FLU6 la etiqueta «Volver» la pone el Semantics de arriba
                child: InkWell(
                  onTap: alTocar,
                  highlightColor: AppColors.border,
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

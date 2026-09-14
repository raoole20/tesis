import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Botón cuadrado de retroceso del encabezado.
///
/// Si no se le pasa [onPressed], usa el `Navigator` más cercano.
class CupoBackButton extends StatelessWidget {
  const CupoBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.iconButton,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: AppColors.border, width: AppSizes.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

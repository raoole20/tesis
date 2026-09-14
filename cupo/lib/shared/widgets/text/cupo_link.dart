import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Enlace de texto suelto, en verde lago: «Olvidé mi clave».
///
/// Se le da un área de toque cómoda sin cambiar su aspecto.
class CupoLink extends StatelessWidget {
  const CupoLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Permite ajustar el tamaño sin perder el color de marca.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(label, style: style ?? AppTypography.link),
      ),
    );
  }
}

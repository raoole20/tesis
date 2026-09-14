import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_button_shell.dart';

/// Acción alternativa: misma jerarquía de tamaño que la principal, pero en
/// blanco con borde. Es la base del botón de Google.
class CupoSecondaryButton extends StatelessWidget {
  const CupoSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CupoButtonShell(
      label: label,
      onPressed: onPressed,
      background: AppColors.surface,
      foreground: AppColors.ink,
      border: const BorderSide(
        color: AppColors.border,
        width: AppSizes.border,
      ),
      leading: leading,
      isLoading: isLoading,
    );
  }
}

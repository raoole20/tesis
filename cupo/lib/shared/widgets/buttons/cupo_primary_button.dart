import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_button_shell.dart';

/// Acción principal de una pantalla: «Crear cuenta», «Verificar», «Entrar».
///
/// Píldora verde lago sólida, ancho completo; al presionarla se oscurece a
/// [AppColors.primaryHover]. Nunca debe haber dos en la misma vista.
class CupoPrimaryButton extends StatelessWidget {
  const CupoPrimaryButton({
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
      background: AppColors.primary,
      foreground: AppColors.onPrimary,
      pressedBackground: AppColors.primaryHover,
      leading: leading,
      isLoading: isLoading,
    );
  }
}

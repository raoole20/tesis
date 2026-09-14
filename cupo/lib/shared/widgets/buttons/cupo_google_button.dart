import 'package:flutter/widgets.dart';

import '../branding/google_glyph.dart';
import 'cupo_secondary_button.dart';

/// Entrada por Google. Cambia solo el rótulo entre registro («Continuar con
/// Google») e inicio de sesión («Entrar con Google»).
class CupoGoogleButton extends StatelessWidget {
  const CupoGoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CupoSecondaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      leading: const GoogleGlyph(),
    );
  }
}

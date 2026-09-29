import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Aviso de error dentro de un formulario.
///
/// Rojo suave sobre texto en tinta, como manda la regla 7 de CLAUDE.md:
/// error → `danger` sobre `dangerSoft`. Es el gemelo de [CupoInfoBanner],
/// que usa el verde suave para lo informativo.
class CupoErrorBanner extends StatelessWidget {
  const CupoErrorBanner({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Text(mensaje, style: AppTypography.body),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Bloque informativo sobre fondo verde suave.
///
/// En «Verificar teléfono» es la salida al error más común: el número está mal.
class CupoInfoBanner extends StatelessWidget {
  const CupoInfoBanner({super.key, required this.child});

  /// Contenido del bloque, normalmente un [CupoInlineLinkText].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: child,
    );
  }
}

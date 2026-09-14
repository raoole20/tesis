import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_logo_mark.dart';
import 'cupo_wordmark.dart';

/// Símbolo y logotipo apilados, como aparecen en la bienvenida.
class CupoLockup extends StatelessWidget {
  const CupoLockup({
    super.key,
    this.markSize = AppSizes.logoTile,
    this.gap = AppSpacing.xl,
  });

  /// Lado del símbolo en dp.
  final double markSize;

  /// Separación entre el símbolo y el logotipo.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupoLogoMark(size: markSize),
        SizedBox(height: gap),
        const CupoWordmark(),
      ],
    );
  }
}

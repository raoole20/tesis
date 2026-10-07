import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_logo_mark.dart';
import 'cupo_wordmark.dart';

/// Símbolo y logotipo juntos.
///
/// - [CupoLockup.new]: apilados, con el mosaico de color, como aparecen en
///   las pantallas de estado.
/// - [CupoLockup.inline]: en línea y en blanco, sin mosaico, como van sobre la
///   foto de cabecera del primer ingreso.
class CupoLockup extends StatelessWidget {
  const CupoLockup({
    super.key,
    this.markSize = AppSizes.logoTile,
    this.gap = AppSpacing.xl,
  }) : wordmarkStyle = null,
       _inline = false;

  const CupoLockup.inline({
    super.key,
    this.markSize = AppSizes.heroGlyph,
    this.gap = AppSpacing.xs,
    this.wordmarkStyle,
  }) : _inline = true;

  /// Lado del símbolo en dp.
  final double markSize;

  /// Separación entre el símbolo y el logotipo.
  final double gap;

  /// Estilo del logotipo en la variante en línea. Por omisión,
  /// [AppTypography.wordmarkHero].
  final TextStyle? wordmarkStyle;

  final bool _inline;

  @override
  Widget build(BuildContext context) {
    if (_inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupoLogoMark(
            size: markSize,
            tile: false,
            foreground: AppColors.onPrimary,
          ),
          SizedBox(width: gap),
          CupoWordmark(style: wordmarkStyle ?? AppTypography.wordmarkHero),
        ],
      );
    }

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

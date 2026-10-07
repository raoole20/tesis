import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Logotipo «Cupo», en Caveat.
///
/// Es el único lugar de la app donde se usa esa familia; el resto va en
/// Manrope (ver [AppTypography]).
class CupoWordmark extends StatelessWidget {
  const CupoWordmark({super.key, this.style, this.fontSize, this.color});

  /// Estilo base. Por omisión, [AppTypography.wordmark]; sobre la foto se usa
  /// [AppTypography.wordmarkHero] o [AppTypography.wordmarkHeroCompact].
  final TextStyle? style;

  /// Tamaño en dp. Por omisión, el del diseño (46 dp).
  final double? fontSize;

  /// Color del logotipo. Por omisión, tinta.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cupo',
      style: (style ?? AppTypography.wordmark).copyWith(
        fontSize: fontSize,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }
}

import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Logotipo «Cupo», en Caveat.
///
/// Es el único lugar de la app donde se usa esa familia; el resto va en
/// Manrope (ver [AppTypography]).
class CupoWordmark extends StatelessWidget {
  const CupoWordmark({super.key, this.fontSize, this.color});

  /// Tamaño en dp. Por omisión, el del diseño (46 dp).
  final double? fontSize;

  /// Color del logotipo. Por omisión, tinta.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cupo',
      style: AppTypography.wordmark.copyWith(
        fontSize: fontSize,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }
}

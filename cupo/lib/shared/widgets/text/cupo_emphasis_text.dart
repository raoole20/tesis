import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Frase con un dato resaltado en negrita dentro.
///
/// Cubre «Te lo mandamos por WhatsApp al **0414 000 0000**.» y
/// «Reenviar en **0:42**».
class CupoEmphasisText extends StatelessWidget {
  const CupoEmphasisText({
    super.key,
    required this.before,
    required this.emphasis,
    this.after = '',
    this.style,
    this.emphasisStyle,
    this.textAlign = TextAlign.start,
  });

  /// Texto anterior al dato.
  final String before;

  /// El dato resaltado.
  final String emphasis;

  /// Texto posterior al dato, normalmente un punto final.
  final String after;

  /// Estilo del texto corriente. Por omisión, [AppTypography.body].
  final TextStyle? style;

  /// Estilo del dato. Por omisión, [AppTypography.bodyStrong].
  final TextStyle? emphasisStyle;

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style ?? AppTypography.body,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: emphasis,
            style: emphasisStyle ?? AppTypography.bodyStrong,
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

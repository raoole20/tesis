import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Frase con un enlace en medio.
///
/// Cubre «¿Ya tienes cuenta? **Iniciar sesión**» al pie de la bienvenida y
/// «¿Número equivocado? **Cámbialo aquí** y te mandamos otro código.» dentro
/// del bloque informativo.
class CupoInlineLinkText extends StatefulWidget {
  const CupoInlineLinkText({
    super.key,
    required this.before,
    required this.linkLabel,
    required this.onTap,
    this.after = '',
    this.style,
    this.linkStyle,
    this.textAlign = TextAlign.center,
  });

  /// Texto anterior al enlace.
  final String before;

  /// Texto tocable.
  final String linkLabel;

  /// Texto posterior al enlace.
  final String after;

  final VoidCallback onTap;

  /// Estilo del texto corriente. Por omisión, [AppTypography.linkLead].
  final TextStyle? style;

  /// Estilo del enlace. Por omisión, [AppTypography.link].
  final TextStyle? linkStyle;

  final TextAlign textAlign;

  @override
  State<CupoInlineLinkText> createState() => _CupoInlineLinkTextState();
}

class _CupoInlineLinkTextState extends State<CupoInlineLinkText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = _handleTap;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleTap() => widget.onTap();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: widget.style ?? AppTypography.linkLead,
        children: [
          TextSpan(text: widget.before),
          TextSpan(
            text: widget.linkLabel,
            style: widget.linkStyle ?? AppTypography.link,
            recognizer: _recognizer,
          ),
          if (widget.after.isNotEmpty) TextSpan(text: widget.after),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}

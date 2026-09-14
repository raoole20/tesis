import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Aclaración bajo un campo: «Te mandamos un código por WhatsApp para
/// verificarlo.»
class CupoFieldHelper extends StatelessWidget {
  const CupoFieldHelper(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.helper);
}

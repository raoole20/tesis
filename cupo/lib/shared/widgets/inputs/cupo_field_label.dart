import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Etiqueta que va encima de un campo: «Nombre y apellido».
class CupoFieldLabel extends StatelessWidget {
  const CupoFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.label);
}

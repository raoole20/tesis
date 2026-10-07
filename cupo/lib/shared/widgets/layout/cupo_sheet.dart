import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Hoja de contenido que se monta sobre la foto de cabecera.
///
/// Es del mismo color que el fondo de la pantalla ([AppColors.background]),
/// así que por abajo se funde con él y solo se notan las esquinas superiores
/// redondeadas. No lleva sombra: el contraste con la foto ya marca el borde
/// (regla 5 de CLAUDE.md).
class CupoSheet extends StatelessWidget {
  const CupoSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
  });

  final Widget child;

  /// Relleno interno.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.sheetTop,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

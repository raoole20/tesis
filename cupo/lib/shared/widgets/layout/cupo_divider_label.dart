import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Separador con un rótulo en medio: «o», «o con tu teléfono».
///
/// Marca el cambio de método de entrada sin usar un título.
class CupoDividerLabel extends StatelessWidget {
  const CupoDividerLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _Rule()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(label, style: AppTypography.meta),
        ),
        const Expanded(child: _Rule()),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: AppColors.border,
      );
}

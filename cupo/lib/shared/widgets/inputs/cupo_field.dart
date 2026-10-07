import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_field_helper.dart';
import 'cupo_field_label.dart';

/// Un campo completo: etiqueta, caja y aclaración opcional.
///
/// Fija la separación entre las tres piezas para que todos los formularios
/// respiren igual.
class CupoField extends StatelessWidget {
  const CupoField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
    this.trailing,
  });

  /// Texto de la etiqueta.
  final String label;

  /// La caja: [CupoTextInput], [CupoPasswordInput] o cualquier otro control.
  final Widget child;

  /// Aclaración bajo la caja. Si es `null`, no ocupa espacio.
  final String? helper;

  /// Acción pegada a la derecha de la etiqueta, por ejemplo el enlace
  /// «¿La olvidaste?» sobre la clave.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: CupoFieldLabel(label)),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          CupoFieldHelper(helper!),
        ],
      ],
    );
  }
}

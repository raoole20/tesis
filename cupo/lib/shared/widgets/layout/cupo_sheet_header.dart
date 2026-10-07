import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../buttons/cupo_back_button.dart';

/// Encabezado de la hoja: retroceso a la izquierda y el nombre del paso
/// centrado.
///
/// A la derecha queda un hueco del mismo ancho que el botón, para que el
/// título quede centrado en la pantalla y no en el espacio que sobra.
class CupoSheetHeader extends StatelessWidget {
  const CupoSheetHeader({super.key, required this.title, this.onBack});

  /// Nombre del paso: «Crear cuenta», «Iniciar sesión».
  final String title;

  /// Acción del retroceso. Por omisión, el `Navigator` más cercano.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CupoBackButton(onPressed: onBack),
        Expanded(
          child: Text(
            title,
            style: AppTypography.metaStrong,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSizes.iconButton),
      ],
    );
  }
}

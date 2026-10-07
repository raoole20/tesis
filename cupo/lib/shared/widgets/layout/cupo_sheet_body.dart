import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'cupo_sheet_header.dart';

/// Contenido de la hoja cuando está desplegada como formulario.
///
/// Arriba el [CupoSheetHeader]; en el medio los [children], que se desplazan
/// cuando no caben (el teclado abierto, el registro largo); abajo el [footer],
/// anclado y siempre visible.
///
/// Necesita una altura acotada: va dentro de una `CupoSheet` que ocupa lo
/// que la foto deja libre.
class CupoSheetBody extends StatelessWidget {
  const CupoSheetBody({
    super.key,
    required this.title,
    this.onBack,
    this.footer,
    required this.children,
  });

  /// Nombre del paso, en el encabezado.
  final String title;

  /// Acción del retroceso. Por omisión, el `Navigator` más cercano.
  final VoidCallback? onBack;

  /// Zona anclada al borde inferior.
  final Widget? footer;

  /// Contenido desplazable, debajo del encabezado.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final pie = footer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        CupoSheetHeader(title: title, onBack: onBack),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (pie != null) ...[const SizedBox(height: AppSpacing.md), pie],
        const SizedBox(height: AppSpacing.screenBottom),
      ],
    );
  }
}

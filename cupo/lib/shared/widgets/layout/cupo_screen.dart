import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Armazón común de las pantallas de Cupo.
///
/// Fija el fondo, el área segura y el margen lateral de 24 dp, y reparte la
/// altura en dos zonas:
///
/// - [children], que ocupa lo que queda libre y se desplaza cuando el teclado
///   se abre o el contenido no cabe;
/// - [footer], anclado abajo y siempre visible.
///
/// Esa división es la que produce el hueco grande del diseño entre el texto y
/// los botones, sin necesidad de espaciadores a mano.
///
/// El fondo es blanco, no [AppColors.background]: las pantallas del primer
/// ingreso son lámina blanca y el gris del tema queda para las vistas con
/// tarjetas.
class CupoScreen extends StatelessWidget {
  const CupoScreen({
    super.key,
    required this.children,
    this.leading,
    this.footer,
    this.topGap = AppSpacing.xs,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// Contenido desplazable.
  final List<Widget> children;

  /// Encabezado alineado a la izquierda, normalmente un [CupoBackButton].
  final Widget? leading;

  /// Zona anclada al borde inferior.
  final Widget? footer;

  /// Separación entre el área segura y el primer elemento.
  final double topGap;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topGap),
              if (leading != null)
                Align(alignment: Alignment.centerLeft, child: leading),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: crossAxisAlignment,
                    children: children,
                  ),
                ),
              ),
              if (footer != null) footer!,
              const SizedBox(height: AppSpacing.screenBottom),
            ],
          ),
        ),
      ),
    );
  }
}

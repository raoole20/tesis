import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import 'cupo_hero.dart';
import 'cupo_sheet.dart';
import 'cupo_sheet_body.dart';

/// Armazón de un paso suelto del primer ingreso, con la hoja ya desplegada:
/// se ve igual que los formularios de la bienvenida cuando la hoja creció.
///
/// Arriba va la foto compacta ([CupoHero] con `compactness: 1`). Encima se
/// monta [CupoSheet] con un [CupoSheetBody]: encabezado, [children]
/// desplazables y [footer] anclado.
///
/// Lo usa la verificación del teléfono, que se abre como ruta propia.
class CupoHeroScreen extends StatelessWidget {
  const CupoHeroScreen({
    super.key,
    required this.title,
    this.onBack,
    this.footer,
    required this.children,
  });

  /// Nombre del paso, en el encabezado de la hoja.
  final String title;

  /// Acción del retroceso. Por omisión, el `Navigator` más cercano.
  final VoidCallback? onBack;

  /// Zona anclada al borde inferior.
  final Widget? footer;

  /// Contenido desplazable, debajo del encabezado.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: AppSizes.heroCompact,
              child: CupoHero(compactness: 1),
            ),
            Positioned(
              left: 0,
              top: AppSizes.heroCompact - AppSizes.heroOverlap,
              right: 0,
              bottom: 0,
              child: CupoSheet(
                child: SafeArea(
                  top: false,
                  child: CupoSheetBody(
                    title: title,
                    onBack: onBack,
                    footer: footer,
                    children: children,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

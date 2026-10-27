import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Cabecera de una pestaña de inicio: el título, una línea de detalle y, a
/// la derecha, una acción —por lo general, el botón de la cuenta—.
///
/// Es la misma tarjeta blanca del saludo de «Hoy», para que cambiar de
/// pestaña no cambie la forma de la parte de arriba.
class CupoTabHeader extends StatelessWidget {
  const CupoTabHeader({
    super.key,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  final String titulo;

  /// Línea pequeña sobre el título: «12 al 16 de octubre».
  final String? detalle;

  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final detalle = this.detalle;
    final accion = this.accion;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detalle != null) ...[
                  Text(detalle, style: AppTypography.meta),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(titulo, style: AppTypography.title),
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

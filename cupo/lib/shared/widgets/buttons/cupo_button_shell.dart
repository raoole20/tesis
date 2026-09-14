import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Caja común de los botones de acción de Cupo.
///
/// Resuelve lo que comparten el botón primario y el secundario —alto fijo,
/// esquinas, ancho completo, estado deshabilitado, indicador de carga y
/// realimentación al tocar— para que cada variante solo tenga que declarar sus
/// colores. No se usa directamente en las pantallas: para eso están
/// [CupoPrimaryButton] y [CupoSecondaryButton].
class CupoButtonShell extends StatelessWidget {
  const CupoButtonShell({
    super.key,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.border,
    this.leading,
    this.isLoading = false,
    this.height = AppSizes.button,
  });

  /// Rótulo del botón.
  final String label;

  /// Acción al tocarlo. Si es `null`, el botón se ve y se comporta como
  /// deshabilitado.
  final VoidCallback? onPressed;

  /// Relleno de la caja.
  final Color background;

  /// Color del rótulo, del icono de carga y del contenido de [leading].
  final Color foreground;

  /// Borde opcional. El botón primario no lo lleva.
  final BorderSide? border;

  /// Contenido a la izquierda del rótulo, por ejemplo un logo.
  final Widget? leading;

  /// Sustituye el contenido por un indicador de progreso y bloquea el toque.
  final bool isLoading;

  /// Alto en dp.
  final double height;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button.copyWith(color: foreground),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: border ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            splashColor: foreground.withValues(alpha: 0.10),
            highlightColor: foreground.withValues(alpha: 0.06),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

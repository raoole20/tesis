import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';
import 'cupo_check_tile.dart';

/// Una opción del [CupoPrefixSelector].
class CupoOpcionPrefijo<T> {
  const CupoOpcionPrefijo({
    required this.valor,
    required this.etiqueta,
    required this.titulo,
    this.descripcion,
    this.icono,
  });

  final T valor;

  /// Lo que se ve dentro del campo: «V», «0414».
  final String etiqueta;

  /// Lo que se ve en la lista: «V · Venezolano».
  final String titulo;

  /// Segunda línea en la lista: «Cédula de identidad».
  final String? descripcion;

  /// Icono de Lucide para el mosaico de la fila.
  final IconData? icono;
}

/// Prefijo cerrado de un campo de texto: la letra de la cédula o el código de
/// la operadora.
///
/// Va en el `prefix` de [CupoTextInput], separado del texto por una línea
/// fina. Con una sola opción es **fijo**: se lee pero no se toca. Con varias,
/// muestra una flecha y al tocarlo abre una hoja con la lista.
///
/// Sin [valor] muestra el [placeholder] en el color de las pistas, para que
/// se note que falta elegir.
class CupoPrefixSelector<T> extends StatelessWidget {
  const CupoPrefixSelector({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onChanged,
    required this.tituloHoja,
    this.placeholder = '—',
    this.enabled = true,
  }) : assert(opciones.length > 0, 'Hace falta al menos una opción.');

  final List<CupoOpcionPrefijo<T>> opciones;
  final T? valor;
  final ValueChanged<T> onChanged;

  /// Encabezado de la hoja de opciones: «Tipo de documento».
  final String tituloHoja;

  /// Lo que se ve mientras no hay [valor].
  final String placeholder;

  final bool enabled;

  bool get _esFijo => opciones.length == 1;

  CupoOpcionPrefijo<T>? get _actual {
    for (final opcion in opciones) {
      if (opcion.valor == valor) return opcion;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final actual = _actual;
    final tocable = enabled && !_esFijo;

    final contenido = Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            actual?.etiqueta ?? placeholder,
            style: actual == null
                ? AppTypography.inputHint
                : AppTypography.input.copyWith(fontWeight: FontWeight.w700),
          ),
          if (!_esFijo) ...[
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              LucideIcons.chevronDown,
              size: AppSizes.iconSmall,
              color: AppColors.textSupport,
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: AppSizes.border,
            height: AppSizes.icon,
            color: AppColors.border,
          ),
        ],
      ),
    );

    if (!tocable) return contenido;

    return Semantics(
      button: true,
      label: '$tituloHoja: ${actual?.etiqueta ?? 'sin elegir'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _elegir(context),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          // El área táctil mínima de Material, aunque el texto sea corto.
          constraints: const BoxConstraints(minHeight: AppSizes.iconButton),
          child: contenido,
        ),
      ),
    );
  }

  Future<void> _elegir(BuildContext context) async {
    // Que el teclado no tape la hoja; el foco vuelve al tocar el número.
    FocusScope.of(context).unfocus();

    final elegido = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      elevation: 0,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (context) => _HojaDeOpciones<T>(
        titulo: tituloHoja,
        opciones: opciones,
        valor: valor,
      ),
    );

    if (elegido != null && elegido != valor) onChanged(elegido);
  }
}

class _HojaDeOpciones<T> extends StatelessWidget {
  const _HojaDeOpciones({
    required this.titulo,
    required this.opciones,
    required this.valor,
  });

  final String titulo;
  final List<CupoOpcionPrefijo<T>> opciones;
  final T? valor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.screenBottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final opcion in opciones) ...[
                      CupoCheckTile(
                        icono: opcion.icono,
                        titulo: opcion.titulo,
                        descripcion: opcion.descripcion,
                        seleccionado: opcion.valor == valor,
                        onPressed: () =>
                            Navigator.of(context).pop(opcion.valor),
                      ),
                      if (opcion != opciones.last)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

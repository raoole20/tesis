import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import 'cupo_focus_ring.dart';

/// Caja de texto de Cupo: fondo blanco, borde fino y esquinas suaves.
///
/// El alto sale del relleno interno ([AppSpacing.md] arriba y abajo) con un
/// mínimo de [AppSizes.field], para que la caja tenga cuerpo y no se lea como
/// una línea sobre el fondo de la pantalla.
///
/// Con el foco, el borde pasa a verde lago y aparece el halo de
/// [CupoFocusRing]. Por eso es `Stateful`: tiene que enterarse de cuándo entra
/// y sale el foco.
///
/// Es solo la caja. La etiqueta y la aclaración las pone [CupoField].
class CupoTextInput extends StatefulWidget {
  const CupoTextInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Texto de ejemplo que se ve cuando el campo está vacío.
  final String? hintText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;

  /// Contenido pegado al borde derecho, por ejemplo el ojo de la clave.
  final Widget? suffix;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CupoTextInput> createState() => _CupoTextInputState();
}

class _CupoTextInputState extends State<CupoTextInput> {
  bool _conFoco = false;

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: AppSizes.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suffix = widget.suffix;

    // `Focus` sin nodo propio escucha el foco de su descendiente, el
    // TextField, sin quitárselo ni meterse en el recorrido con el teclado.
    final campo = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (conFoco) => setState(() => _conFoco = conFoco),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.field),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: AppTypography.input,
          cursorColor: AppColors.primary,
          cursorWidth: 1.6,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: false,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.backgroundAlt,
            hintText: widget.hintText,
            hintStyle: AppTypography.inputHint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: suffix,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            enabledBorder: _border(AppColors.border),
            disabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary),
            border: _border(AppColors.border),
          ),
        ),
      ),
    );

    return CupoFocusRing(
      visible: _conFoco && widget.enabled,
      radius: AppRadius.md,
      child: campo,
    );
  }
}

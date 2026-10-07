import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Caja de texto de Cupo: fondo blanco, borde fino y esquinas suaves.
///
/// El alto sale del relleno interno ([AppSpacing.md] arriba y abajo) con un
/// mínimo de [AppSizes.field], para que la caja tenga cuerpo y no se lea como
/// una línea sobre el fondo de la pantalla.
///
/// Es solo la caja. La etiqueta y la aclaración las pone [CupoField].
class CupoTextInput extends StatelessWidget {
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

  /// Contenido pegado al borde derecho, por ejemplo el enlace «Ver».
  final Widget? suffix;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.field),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofillHints: autofillHints,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.input,
        cursorColor: AppColors.primary,
        cursorWidth: 1.6,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: false,
          filled: true,
          fillColor: enabled ? AppColors.surface : AppColors.backgroundAlt,
          hintText: hintText,
          hintStyle: AppTypography.inputHint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: suffix,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          enabledBorder: _border(AppColors.border, AppSizes.border),
          disabledBorder: _border(AppColors.border, AppSizes.border),
          focusedBorder: _border(AppColors.primary, AppSizes.borderFocused),
          border: _border(AppColors.border, AppSizes.border),
        ),
      ),
    );
  }
}

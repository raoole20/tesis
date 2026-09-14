import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'cupo_text_input.dart';

/// Campo de clave con el enlace «Ver» / «Ocultar» dentro de la caja.
class CupoPasswordInput extends StatefulWidget {
  const CupoPasswordInput({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = '••••••••',
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CupoPasswordInput> createState() => _CupoPasswordInputState();
}

class _CupoPasswordInputState extends State<CupoPasswordInput> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return CupoTextInput(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      obscureText: _hidden,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: GestureDetector(
        onTap: () => setState(() => _hidden = !_hidden),
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: _hidden ? 'Mostrar la clave' : 'Ocultar la clave',
          child: Text(
            _hidden ? 'Ver' : 'Ocultar',
            style: AppTypography.link.copyWith(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

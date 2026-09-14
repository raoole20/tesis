import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import 'cupo_otp_box.dart';

/// Fila de casillas para escribir el código de verificación.
///
/// Por dentro es un único campo de texto invisible sobre las casillas: así
/// funcionan el teclado, el pegado y el autorrelleno del código de WhatsApp
/// (`AutofillHints.oneTimeCode`) sin repartir el foco entre seis campos.
class CupoOtpInput extends StatefulWidget {
  const CupoOtpInput({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
  });

  /// Cantidad de casillas.
  final int length;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Se llama con el código parcial en cada tecla.
  final ValueChanged<String>? onChanged;

  /// Se llama una vez que hay [length] dígitos.
  final ValueChanged<String>? onCompleted;

  @override
  State<CupoOtpInput> createState() => _CupoOtpInputState();
}

class _CupoOtpInputState extends State<CupoOtpInput> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CupoOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onTextChanged() {
    setState(() {});
    final code = _controller.text;
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;

    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CupoOtpBox(
                  digit: i < code.length ? code[i] : '',
                  isActive: i == code.length && _focusNode.hasFocus,
                ),
              ),
            ],
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              style: AppTypography.otpDigit,
              decoration: const InputDecoration.collapsed(hintText: ''),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onTap: () => _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

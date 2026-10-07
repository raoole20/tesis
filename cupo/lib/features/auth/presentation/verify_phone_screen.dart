import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';

/// L3 — Verificar teléfono.
///
/// Seis casillas, un solo campo activo y una salida clara si el número está
/// mal: ese es el error más común y por eso tiene su propio bloque.
class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key, this.phoneNumber = '0414 000 0000'});

  /// Número al que se mandó el código, tal como se le muestra a la persona.
  final String phoneNumber;

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  static const int _codeLength = 6;

  final _code = TextEditingController();
  bool _complete = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    // Aquí entra la verificación contra el backend.
  }

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Escribe el código', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        CupoEmphasisText(
          before: 'Te lo mandamos por WhatsApp al ',
          emphasis: widget.phoneNumber,
          after: '.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        CupoOtpInput(
          length: _codeLength,
          controller: _code,
          autofocus: true,
          onChanged: (code) =>
              setState(() => _complete = code.length == _codeLength),
        ),
        const SizedBox(height: AppSpacing.lg),
        CupoResendCountdown(onResend: () {}),
        const SizedBox(height: AppSpacing.xl),
        CupoInfoBanner(
          child: CupoInlineLinkText(
            before: '¿Número equivocado? ',
            linkLabel: 'Cámbialo aquí',
            after: ' y te mandamos otro código.',
            onTap: () => Navigator.of(context).maybePop(),
            style: AppTypography.body,
            textAlign: TextAlign.start,
          ),
        ),
      ],
      footer: CupoPrimaryButton(
        label: 'Verificar',
        onPressed: _complete ? _verify : null,
      ),
    );
  }
}

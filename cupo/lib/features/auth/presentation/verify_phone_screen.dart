import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';

/// L3 — Verificar teléfono.
///
/// Seis casillas y un solo campo activo. El título dice adónde llegó el
/// código, con el número enmascarado: si el número está mal, que es el error
/// más común, el botón de retroceso lleva de vuelta a corregirlo.
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

  /// Solo los últimos cuatro dígitos: «••• 0000».
  String get _numeroEnmascarado {
    final digitos = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final cola = digitos.length > 4
        ? digitos.substring(digitos.length - 4)
        : digitos;
    return '••• $cola';
  }

  void _verify() {
    // Aquí entra la verificación contra el backend.
  }

  @override
  Widget build(BuildContext context) {
    return CupoHeroScreen(
      title: 'Crear cuenta',
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Escribe el código que te llegó al $_numeroEnmascarado',
          style: AppTypography.title,
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoOtpInput(
          length: _codeLength,
          controller: _code,
          autofocus: true,
          onChanged: (code) =>
              setState(() => _complete = code.length == _codeLength),
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoPrimaryButton(
          label: 'Continuar',
          onPressed: _complete ? _verify : null,
        ),
        const SizedBox(height: AppSpacing.md),
        CupoResendCountdown(onResend: () {}),
      ],
    );
  }
}

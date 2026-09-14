import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Una casilla del código de verificación.
///
/// Tres estados: vacía, con dígito y activa (la que recibe la próxima tecla).
class CupoOtpBox extends StatelessWidget {
  const CupoOtpBox({
    super.key,
    required this.digit,
    this.isActive = false,
  });

  /// Dígito escrito, o cadena vacía.
  final String digit;

  /// `true` en la casilla donde caerá la próxima tecla.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.otpBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? AppSizes.borderFocused : AppSizes.border,
        ),
      ),
      child: digit.isNotEmpty
          ? Text(digit, style: AppTypography.otpDigit)
          : (isActive ? const _Caret() : null),
    );
  }
}

/// Barra vertical parpadeante de la casilla activa.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink.drive(
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween<double>(1), weight: 50),
          TweenSequenceItem(tween: ConstantTween<double>(0), weight: 50),
        ]),
      ),
      child: Container(
        width: 2,
        height: 26,
        decoration: const BoxDecoration(color: AppColors.ink),
      ),
    );
  }
}

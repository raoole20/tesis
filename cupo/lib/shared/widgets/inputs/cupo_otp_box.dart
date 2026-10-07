import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import 'cupo_focus_ring.dart';

/// Una casilla del código de verificación.
///
/// Tres estados:
///
/// - **vacía**: relleno [AppColors.backgroundMuted], sin borde;
/// - **con dígito**: blanca con borde fino;
/// - **activa** (la que recibe la próxima tecla): blanca, borde verde lago,
///   halo de foco y el cursor parpadeando.
class CupoOtpBox extends StatelessWidget {
  const CupoOtpBox({super.key, required this.digit, this.isActive = false});

  /// Dígito escrito, o cadena vacía.
  final String digit;

  /// `true` en la casilla donde caerá la próxima tecla.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final vacia = digit.isEmpty && !isActive;

    return CupoFocusRing(
      visible: isActive,
      radius: AppRadius.sm,
      child: Container(
        height: AppSizes.otpBox,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: vacia ? AppColors.backgroundMuted : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: vacia
              ? null
              : Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: AppSizes.border,
                ),
        ),
        child: digit.isNotEmpty
            ? Text(digit, style: AppTypography.otpDigit)
            : (isActive ? const _Caret() : null),
      ),
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
        width: 1.5,
        height: 22,
        decoration: const BoxDecoration(color: AppColors.primary),
      ),
    );
  }
}

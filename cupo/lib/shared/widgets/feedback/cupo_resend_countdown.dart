import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../text/cupo_emphasis_text.dart';
import '../text/cupo_link.dart';

/// Contador de reenvío del código: «Reenviar en 0:42».
///
/// Mientras corre, el reenvío no se puede tocar —esa es la razón de que el
/// tiempo esté a la vista—. Al llegar a cero se convierte en un enlace.
class CupoResendCountdown extends StatefulWidget {
  const CupoResendCountdown({
    super.key,
    required this.onResend,
    this.duration = const Duration(seconds: 42),
    this.waitingLabel = 'Reenviar en ',
    this.readyLabel = 'Reenviar el código',
  });

  /// Se llama cuando se toca el enlace, ya agotado el tiempo.
  final VoidCallback onResend;

  /// Cuánto hay que esperar antes de poder reenviar.
  final Duration duration;

  /// Texto anterior al tiempo restante.
  final String waitingLabel;

  /// Rótulo del enlace una vez cumplido el plazo.
  final String readyLabel;

  @override
  State<CupoResendCountdown> createState() => _CupoResendCountdownState();
}

class _CupoResendCountdownState extends State<CupoResendCountdown> {
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _remaining = widget.duration.inSeconds;
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  static String _format(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CupoLink(
          label: widget.readyLabel,
          onPressed: () {
            widget.onResend();
            setState(_start);
          },
          style: AppTypography.link.copyWith(fontSize: 14),
        ),
      );
    }

    return CupoEmphasisText(
      before: widget.waitingLabel,
      emphasis: _format(_remaining),
      style: AppTypography.meta,
      emphasisStyle: AppTypography.metaStrong,
    );
  }
}

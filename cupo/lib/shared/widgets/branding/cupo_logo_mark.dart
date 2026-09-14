import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';

/// Símbolo de marca de Cupo: un mosaico redondeado con un punto y un arco.
///
/// El punto es el pasajero y el arco el recorrido que lo alcanza. Se dibuja en
/// vez de cargarse como imagen para que quede nítido en cualquier tamaño y para
/// que el color salga de [AppColors].
///
/// Todas las proporciones son relativas al lado del mosaico, medidas sobre el
/// diseño a 78 dp:
///
/// | pieza            | proporción del lado |
/// |------------------|---------------------|
/// | radio de esquina | 31 %                |
/// | punto (diámetro) | 18,8 %              |
/// | arco (radio)     | 22,8 %              |
/// | arco (grosor)    | 6 %                 |
class CupoLogoMark extends StatelessWidget {
  const CupoLogoMark({
    super.key,
    this.size = AppSizes.logoTile,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
  });

  /// Lado del mosaico en dp.
  final double size;

  /// Color del mosaico.
  final Color background;

  /// Color del punto y el arco.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CupoLogoMarkPainter(
          background: background,
          foreground: foreground,
        ),
        isComplex: false,
      ),
    );
  }
}

class _CupoLogoMarkPainter extends CustomPainter {
  const _CupoLogoMarkPainter({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  static const double _cornerRatio = 0.31;
  static const double _dotRatio = 0.094; // radio
  static const double _arcRatio = 0.228; // radio
  static const double _strokeRatio = 0.060;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Offset.zero & Size.square(side);
    final centre = rect.center;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(side * _cornerRatio)),
      Paint()..color = background,
    );

    final ink = Paint()..color = foreground;
    canvas.drawCircle(centre, side * _dotRatio, ink);

    // Media circunferencia derecha: de las 12 a las 6, en sentido horario.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: side * _arcRatio),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * _strokeRatio
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CupoLogoMarkPainter old) =>
      old.background != background || old.foreground != foreground;
}

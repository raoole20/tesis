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
///
/// Con `tile: false` se dibuja solo el glifo —punto y arco, sin mosaico—, como
/// va sobre la foto de cabecera. Entonces las proporciones salen del SVG de
/// «Cupo Login v2» (caja de 66): punto de radio 10, arco de radio 24 y grosor 7.
class CupoLogoMark extends StatelessWidget {
  const CupoLogoMark({
    super.key,
    this.size = AppSizes.logoTile,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.tile = true,
  });

  /// Lado del mosaico en dp.
  final double size;

  /// Color del mosaico.
  final Color background;

  /// Color del punto y el arco.
  final Color foreground;

  /// Si se dibuja el mosaico de fondo. Sin él, [background] no se usa.
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CupoLogoMarkPainter(
          background: background,
          foreground: foreground,
          tile: tile,
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
    required this.tile,
  });

  final Color background;
  final Color foreground;
  final bool tile;

  static const double _cornerRatio = 0.31;
  static const double _dotRatio = 0.094; // radio
  static const double _arcRatio = 0.228; // radio
  static const double _strokeRatio = 0.060;

  // Glifo suelto: 10, 24 y 7 sobre una caja de 66.
  static const double _glyphDotRatio = 10 / 66;
  static const double _glyphArcRatio = 24 / 66;
  static const double _glyphStrokeRatio = 7 / 66;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Offset.zero & Size.square(side);
    final centre = rect.center;

    if (tile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(side * _cornerRatio)),
        Paint()..color = background,
      );
    }

    final dot = tile ? _dotRatio : _glyphDotRatio;
    final arc = tile ? _arcRatio : _glyphArcRatio;
    final stroke = tile ? _strokeRatio : _glyphStrokeRatio;

    final ink = Paint()..color = foreground;
    canvas.drawCircle(centre, side * dot, ink);

    // Media circunferencia derecha: de las 12 a las 6, en sentido horario.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: side * arc),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CupoLogoMarkPainter old) =>
      old.background != background ||
      old.foreground != foreground ||
      old.tile != tile;
}

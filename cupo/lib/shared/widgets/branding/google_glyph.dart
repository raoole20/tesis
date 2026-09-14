import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// La «G» de Google, dibujada a mano para no depender de un asset.
///
/// Es una reconstrucción a partir de arcos: fiel en proporción y color, pero no
/// es el archivo oficial. Si más adelante se agrega el asset de marca de Google
/// (o el paquete `flutter_svg`), basta cambiar el cuerpo de este widget: nadie
/// más lo dibuja.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 20});

  /// Lado del glifo en dp.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  const _GoogleGlyphPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  /// Grosor del anillo como fracción del lado.
  static const double _strokeRatio = 0.24;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final stroke = side * _strokeRatio;
    final centre = Offset(side / 2, side / 2);
    final radius = (side - stroke) / 2;
    final box = Rect.fromCircle(center: centre, radius: radius);

    void segment(Color color, double fromDeg, double sweepDeg) {
      canvas.drawArc(
        box,
        fromDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // 0° son las 3 en punto y los ángulos crecen en sentido horario.
    segment(_red, 200, 115); // de arriba a la izquierda, pasando por las 12
    segment(_blue, -45, 45); // de la 1 a las 3
    segment(_green, 12, 78); // de las 3 a las 6
    segment(_yellow, 90, 110); // de las 6 a las 9

    // Travesaño azul: del centro al borde derecho, a la altura del eje.
    canvas.drawRect(
      Rect.fromLTRB(
        centre.dx - stroke * 0.1,
        centre.dy - stroke / 2,
        centre.dx + radius + stroke / 2,
        centre.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGlyphPainter oldDelegate) => false;
}

import 'package:flutter/widgets.dart';

/// Radios de esquina de Cupo, en dp.
///
/// [sm] es el mismo valor que `AppTheme.radius`, que es el que aplican los
/// componentes de Material a través del tema. Los otros dos no tienen
/// equivalente en Material: salieron de medir el diseño.
abstract final class AppRadius {
  /// 12 dp — campos de texto.
  static const double sm = 12;

  /// 14 dp — botones, botón de retroceso, casillas de código y
  /// bloques informativos.
  static const double md = 14;

  /// 24 dp — mosaico del símbolo de marca (≈31 % de su lado).
  static const double brand = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brandAll = BorderRadius.all(Radius.circular(brand));
}

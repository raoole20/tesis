import 'package:flutter/widgets.dart';

/// Radios de esquina de Cupo, en dp.
///
/// [sm] es el mismo valor que `AppTheme.radius`, que es el que aplican los
/// componentes de Material a través del tema. Los demás no tienen
/// equivalente en Material: salieron de medir el diseño. Los botones de
/// acción no usan ninguno: son píldora (`StadiumBorder`).
abstract final class AppRadius {
  /// 12 dp — casillas del código de verificación.
  static const double sm = 12;

  /// 14 dp — campos de texto, opciones seleccionables y bloques
  /// informativos.
  static const double md = 14;

  /// 24 dp — mosaico del símbolo de marca (≈31 % de su lado).
  static const double brand = 24;

  /// 28 dp — esquinas superiores de la hoja que se monta sobre la foto.
  static const double sheet = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brandAll = BorderRadius.all(Radius.circular(brand));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

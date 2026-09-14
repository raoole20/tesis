/// Escala de espaciado de Cupo, en dp.
///
/// Todas las separaciones del diseño caen en esta escala. No uses números
/// sueltos en los widgets: si hace falta un valor nuevo, se agrega aquí.
abstract final class AppSpacing {
  /// 4 dp.
  static const double xxs = 4;

  /// 8 dp — separación entre una etiqueta y su campo.
  static const double xs = 8;

  /// 12 dp — separación entre dos botones apilados.
  static const double sm = 12;

  /// 16 dp — separación entre un campo y la etiqueta del siguiente.
  static const double md = 16;

  /// 20 dp — relleno horizontal interno de campos y botones.
  static const double lg = 20;

  /// 24 dp — margen lateral de todas las pantallas.
  static const double xl = 24;

  /// 32 dp — separación entre el encabezado y el primer bloque de contenido.
  static const double xxl = 32;

  /// 48 dp — separación entre la marca y el titular en la bienvenida.
  static const double xxxl = 48;

  /// Margen lateral estándar de pantalla (390 dp de ancho → 342 dp útiles).
  static const double screenH = xl;

  /// Margen inferior estándar, por dentro del área segura.
  static const double screenBottom = xl;
}

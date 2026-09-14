/// Alturas y tamaños fijos tomados del diseño, en dp.
///
/// El lienzo de referencia es Android 390×844.
abstract final class AppSizes {
  /// Alto de los botones de acción (primario y secundario).
  static const double button = 60;

  /// Alto de los campos de texto.
  static const double field = 56;

  /// Lado del botón cuadrado de retroceso.
  static const double iconButton = 44;

  /// Alto de cada casilla del código de verificación.
  static const double otpBox = 68;

  /// Lado del mosaico del símbolo de marca en la bienvenida.
  static const double logoTile = 78;

  /// Grosor de los bordes de campos, casillas y botones secundarios.
  static const double border = 1.5;

  /// Grosor del borde cuando el control tiene el foco.
  static const double borderFocused = 2;
}

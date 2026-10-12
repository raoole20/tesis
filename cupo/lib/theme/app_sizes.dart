/// Alturas y tamaños fijos tomados del diseño, en dp.
///
/// El lienzo de referencia es Android 390×844 («Cupo Login v2»).
abstract final class AppSizes {
  /// Alto de los botones de acción (primario y secundario).
  static const double button = 56;

  /// Alto mínimo de los campos de texto; el relleno interno puede crecerlo.
  static const double field = 52;

  /// Área táctil del botón de retroceso: los 48 dp mínimos de Material. Es
  /// mayor que el círculo visible ([backButton]) para que sea cómodo de tocar.
  static const double iconButton = 48;

  /// Diámetro visible del botón circular de retroceso.
  static const double backButton = 36;

  /// Alto de cada casilla del código de verificación.
  static const double otpBox = 56;

  /// Lado del mosaico del símbolo de marca en las pantallas de estado.
  static const double logoTile = 78;

  /// Lado del símbolo sin mosaico sobre la foto de la bienvenida.
  static const double heroGlyph = 26;

  /// Lado del símbolo sin mosaico sobre la cabecera compacta.
  static const double heroGlyphCompact = 22;

  /// Alto de la foto de cabecera en registro, código e inicio de sesión.
  static const double heroCompact = 208;

  /// Alto de la hoja plegada en la bienvenida, sin contar el margen inferior
  /// del sistema. La foto se queda con el resto de la pantalla.
  static const double welcomeSheet = 320;

  /// Cuánto se monta la hoja de contenido sobre la foto de cabecera.
  static const double heroOverlap = 40;

  /// Ancho máximo del titular sobre la foto de la bienvenida.
  static const double heroHeadlineMaxWidth = 300;

  /// Grosor de los bordes de campos, casillas y botones secundarios.
  static const double border = 1;

  /// Grosor del halo de foco ([AppColors.primaryRing]) por fuera del borde.
  static const double focusRing = 3;

  /// Lado del mosaico cuadrado que lleva el icono de una opción.
  static const double choiceIconTile = 40;

  /// Lado de los iconos de Lucide dentro de opciones y pasos.
  static const double icon = 20;

  /// Lado de los iconos de Lucide dentro de un círculo de paso.
  static const double iconSmall = 16;

  /// Diámetro del círculo numerado de un paso.
  static const double stepDot = 24;

  /// Grosor de la línea que une dos pasos.
  static const double stepConnector = 2;

  /// Lado del marcador de la casa sobre el mapa.
  static const double mapPin = 44;

  /// Lado del punto que marca la ubicación actual sobre el mapa.
  static const double mapDot = 16;

  /// Grosor del borde blanco de los marcadores del mapa.
  static const double mapMarkerBorder = 2;
}

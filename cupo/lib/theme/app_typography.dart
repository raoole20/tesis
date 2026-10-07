import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía de Cupo.
///
/// - **Teko (500–600)**: la voz deportiva. Solo titular, títulos de pantalla
///   y rótulos de botón —[display], [title], [button]—, vía [teko].
/// - **Manrope (400–800)**: todo lo demás: cuerpo, campos, etiquetas,
///   enlaces y el [textTheme] de Material.
/// - **Caveat (700)**: exclusivamente el logotipo "Cupo".
///
/// Nunca uses Caveat fuera de [logo] ni Teko fuera de esos tres papeles;
/// nunca agregues una cuarta familia.
abstract final class AppTypography {
  /// Familia base de la UI.
  static TextStyle manrope({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  /// Familia deportiva, para titulares, títulos y botones.
  ///
  /// Teko es muy condensada y de ojo pequeño: a igual tamaño se ve bastante
  /// más chica que Manrope. Por eso sus tamaños son mayores, y la altura de
  /// línea baja, porque trae mucho aire vertical de fábrica.
  static TextStyle teko({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.teko(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.ink,
    );
  }

  /// Logotipo "Cupo". Único uso permitido de Caveat.
  static TextStyle logo({double size = 32, Color color = AppColors.primary}) {
    return GoogleFonts.caveat(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static final TextTheme textTheme = TextTheme(
    displayLarge: manrope(size: 40, weight: FontWeight.w800, height: 1.15),
    displayMedium: manrope(size: 34, weight: FontWeight.w800, height: 1.18),
    displaySmall: manrope(size: 30, weight: FontWeight.w700, height: 1.2),
    headlineLarge: manrope(size: 28, weight: FontWeight.w700, height: 1.22),
    headlineMedium: manrope(size: 24, weight: FontWeight.w700, height: 1.25),
    headlineSmall: manrope(size: 21, weight: FontWeight.w700, height: 1.3),
    titleLarge: manrope(size: 19, weight: FontWeight.w700, height: 1.3),
    titleMedium: manrope(size: 17, weight: FontWeight.w600, height: 1.35),
    titleSmall: manrope(size: 15, weight: FontWeight.w600, height: 1.4),
    bodyLarge: manrope(size: 16, weight: FontWeight.w400, height: 1.5),
    bodyMedium: manrope(size: 14, weight: FontWeight.w400, height: 1.5),
    bodySmall: manrope(
      size: 13,
      weight: FontWeight.w400,
      height: 1.45,
      color: AppColors.textSecondary,
    ),
    labelLarge: manrope(size: 15, weight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium: manrope(size: 13, weight: FontWeight.w600, letterSpacing: 0.2),
    labelSmall: manrope(
      size: 11,
      weight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.textSupport,
    ),
  );

  // === Estilos del primer ingreso =======================================
  //
  // Medidos sobre el diseño «Cupo Login v2» (Android 390×844). El [textTheme] de
  // arriba cubre la escala general de Material; estos son los papeles concretos
  // que el diseño necesita y que no existen como ranura de Material —el enlace,
  // el aviso legal, el dígito del código, el texto de ejemplo de un campo—.
  // Todos salen de [manrope], así que la familia sigue siendo una sola.

  /// Logotipo de las pantallas de estado, en tinta.
  static final TextStyle wordmark = logo(size: 46, color: AppColors.ink);

  /// Logotipo sobre la foto de la bienvenida.
  static final TextStyle wordmarkHero = logo(
    size: 36,
    color: AppColors.onPrimary,
  );

  /// Logotipo sobre la cabecera compacta de registro, código e inicio de
  /// sesión.
  static final TextStyle wordmarkHeroCompact = logo(
    size: 30,
    color: AppColors.onPrimary,
  );

  /// Titular de la bienvenida: «Tu puesto fijo hasta la URBE». Va sobre la
  /// foto, así que la pantalla le impone [AppColors.onPrimary].
  static final TextStyle display = teko(
    size: 48,
    weight: FontWeight.w600,
    height: 0.95,
    letterSpacing: 0.2,
  );

  /// Título de pantalla: «Crea tu cuenta», «Qué bueno verte».
  static final TextStyle title = teko(
    size: 34,
    weight: FontWeight.w600,
    height: 1,
    letterSpacing: 0.2,
  );

  /// Subtítulo de sección o tarjeta. Es el mismo de [textTheme], para que no
  /// haya dos versiones del estilo.
  static final TextStyle titleMedium = textTheme.titleMedium!;

  /// Párrafo explicativo bajo el título.
  static final TextStyle body = manrope(
    size: 16,
    weight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  /// Texto de apoyo pequeño. Es el mismo de [textTheme].
  static final TextStyle bodySmall = textTheme.bodySmall!;

  /// Igual que [body] pero en tinta plena, para el dato dentro de la frase.
  static final TextStyle bodyStrong = manrope(
    size: 16,
    weight: FontWeight.w700,
    height: 1.45,
  );

  /// Etiqueta sobre un campo: «Nombre y apellido».
  static final TextStyle label = manrope(
    size: 13,
    weight: FontWeight.w700,
    height: 1.3,
  );

  /// Texto escrito por la persona dentro de un campo.
  static final TextStyle input = manrope(
    size: 15,
    weight: FontWeight.w400,
    height: 1.2,
  );

  /// Texto de ejemplo dentro de un campo vacío.
  static final TextStyle inputHint = manrope(
    size: 15,
    weight: FontWeight.w400,
    height: 1.2,
    color: AppColors.textSupportSoft,
  );

  /// Aclaración bajo un campo.
  static final TextStyle helper = manrope(
    size: 13,
    weight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSupport,
  );

  /// Dígito dentro de una casilla del código de verificación.
  static final TextStyle otpDigit = manrope(
    size: 20,
    weight: FontWeight.w700,
    height: 1.1,
  );

  /// Rótulo dentro de un botón. El botón le impone el color.
  static final TextStyle button = teko(
    size: 22,
    weight: FontWeight.w500,
    height: 1,
    letterSpacing: 0.6,
  );

  /// Enlace de texto: «Inicia sesión», «Créala».
  static final TextStyle link = manrope(
    size: 14,
    weight: FontWeight.w700,
    height: 1.4,
    color: AppColors.primaryDeep,
  );

  /// Enlace pequeño junto a la etiqueta de un campo: «¿La olvidaste?».
  static final TextStyle linkSmall = manrope(
    size: 13,
    weight: FontWeight.w700,
    height: 1.3,
    color: AppColors.primaryDeep,
  );

  /// Texto que acompaña a un enlace: «¿Ya tienes cuenta?».
  static final TextStyle linkLead = manrope(
    size: 14,
    weight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Texto secundario pequeño: contador de reenvío, rótulo del separador.
  static final TextStyle meta = manrope(
    size: 14,
    weight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  /// Igual que [meta] pero en negrita.
  static final TextStyle metaStrong = manrope(
    size: 14,
    weight: FontWeight.w700,
    height: 1.3,
  );

  /// Aviso legal al pie de la bienvenida.
  static final TextStyle legal = manrope(
    size: 12,
    weight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSupport,
  );

  /// Documento citado dentro del aviso legal: «Términos», «Aviso de
  /// privacidad».
  static final TextStyle legalStrong = manrope(
    size: 12,
    weight: FontWeight.w700,
    height: 1.5,
  ).copyWith(decoration: TextDecoration.underline);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía de Cupo.
///
/// - **Manrope (400–800)**: toda la UI, títulos y texto.
/// - **Caveat (700)**: exclusivamente el logotipo "Cupo".
///
/// Nunca uses Caveat fuera de [logo]; nunca uses otra familia para la UI.
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
  // Medidos sobre el diseño «Cupo Login» (Android 390×844). El [textTheme] de
  // arriba cubre la escala general de Material; estos son los papeles concretos
  // que el diseño necesita y que no existen como ranura de Material —el enlace,
  // el aviso legal, el dígito del código, el texto de ejemplo de un campo—.
  // Todos salen de [manrope], así que la familia sigue siendo una sola.

  /// Logotipo de la bienvenida, en tinta.
  static final TextStyle wordmark = logo(size: 46, color: AppColors.ink);

  /// Titular de la bienvenida: «Tu puesto fijo hasta la URBE».
  static final TextStyle display = manrope(
    size: 32,
    weight: FontWeight.w800,
    height: 1.15,
  );

  /// Título de pantalla: «Crea tu cuenta», «Escribe el código».
  static final TextStyle title = manrope(
    size: 30,
    weight: FontWeight.w800,
    height: 1.2,
  );

  /// Párrafo explicativo bajo el título.
  static final TextStyle body = manrope(
    size: 16,
    weight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  /// Igual que [body] pero en tinta plena, para el dato dentro de la frase.
  static final TextStyle bodyStrong = manrope(
    size: 16,
    weight: FontWeight.w700,
    height: 1.45,
  );

  /// Etiqueta sobre un campo: «Nombre y apellido».
  static final TextStyle label = manrope(
    size: 14,
    weight: FontWeight.w700,
    height: 1.3,
  );

  /// Texto escrito por la persona dentro de un campo.
  static final TextStyle input = manrope(
    size: 16,
    weight: FontWeight.w400,
    height: 1.2,
  );

  /// Texto de ejemplo dentro de un campo vacío.
  static final TextStyle inputHint = manrope(
    size: 16,
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
    size: 24,
    weight: FontWeight.w700,
    height: 1.1,
  );

  /// Rótulo dentro de un botón. El botón le impone el color.
  static final TextStyle button = manrope(
    size: 16,
    weight: FontWeight.w700,
    height: 1.2,
  );

  /// Enlace de texto: «Iniciar sesión», «Olvidé mi clave».
  static final TextStyle link = manrope(
    size: 15,
    weight: FontWeight.w700,
    height: 1.4,
    color: AppColors.primary,
  );

  /// Texto que acompaña a un enlace: «¿Ya tienes cuenta?».
  static final TextStyle linkLead = manrope(
    size: 15,
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
    color: AppColors.textSupportSoft,
  );
}

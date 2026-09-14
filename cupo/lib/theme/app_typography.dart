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
}

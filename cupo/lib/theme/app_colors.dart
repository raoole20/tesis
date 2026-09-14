import 'package:flutter/material.dart';

/// Paleta de marca de Cupo.
///
/// La fuente de verdad son los valores OkLCH documentados en `CLAUDE.md`;
/// aquí se expresan como `Color` en sRGB. No uses literales de color fuera
/// de este archivo: cualquier tono nuevo se agrega como token aquí.
abstract final class AppColors {
  // --- Verde lago (primario) -------------------------------------------
  /// oklch(0.460 0.09 195) — botones, símbolo, acentos.
  static const Color primary = Color(0xFF007C8A);

  /// oklch(0.400 0.09 195) — hover / pressed.
  static const Color primaryHover = Color(0xFF006B78);

  /// oklch(0.360 0.09 195) — texto de marca sobre fondos claros.
  static const Color primaryDeep = Color(0xFF005F6C);

  /// oklch(0.240 0.09 195) — texto de marca de máximo contraste.
  static const Color primaryDarkest = Color(0xFF003D4B);

  /// oklch(0.965 0.018 195) — fondo suave de bloques informativos.
  static const Color primarySoft = Color(0xFFE7F4F5);

  /// Contenido sobre [primary].
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Neutros ----------------------------------------------------------
  /// oklch(0.2 0.01 200) — tinta, texto principal.
  static const Color ink = Color(0xFF1C2224);

  /// oklch(0.46 0.01 200) — texto secundario.
  static const Color textSecondary = Color(0xFF5F6A6C);

  /// oklch(0.55 0.01 200) — texto de apoyo.
  static const Color textSupport = Color(0xFF798487);

  /// oklch(0.6 0.01 200) — apoyo de menor jerarquía (placeholders, hints).
  static const Color textSupportSoft = Color(0xFF889396);

  /// oklch(0.89 0.006 200) — bordes y divisores.
  static const Color border = Color(0xFFDDE0E0);

  /// oklch(0.975 0.004 200) — fondo base.
  static const Color background = Color(0xFFF9FCFC);

  /// oklch(0.965 0.004 200) — fondo alterno / superficies elevadas.
  static const Color backgroundAlt = Color(0xFFF6F9F9);

  /// Superficie de tarjetas y hojas.
  static const Color surface = Color(0xFFFFFFFF);

  // --- Semánticos -------------------------------------------------------
  /// oklch(0.55 0.13 150) — confirmado.
  static const Color success = Color(0xFF18A06A);

  /// oklch(0.95 0.05 150) — fondo de estado confirmado.
  static const Color successSoft = Color(0xFFD3F9E3);

  /// oklch(0.62 0.14 88) — pendiente / próximo a vencer.
  static const Color warning = Color(0xFFC98A00);

  /// oklch(0.95 0.06 88) — fondo de estado pendiente.
  static const Color warningSoft = Color(0xFFFFEAC2);

  /// oklch(0.55 0.16 25) — error / cancelado.
  ///
  /// Derivado: la guía de marca no define un rojo, se construyó con la misma
  /// luminosidad y croma que [success]. Ajustar si marca define uno propio.
  static const Color danger = Color(0xFFBD413F);

  /// oklch(0.95 0.05 25) — fondo de estado de error.
  static const Color dangerSoft = Color(0xFFFFE2DE);
}

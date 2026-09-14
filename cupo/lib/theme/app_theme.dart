import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Tema único de Cupo. Toda pantalla debe leer color y tipografía desde
/// `Theme.of(context)`; no declares estilos sueltos ni colores literales.
abstract final class AppTheme {
  /// Radio de esquina estándar de la app.
  static const double radius = 12;

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(radius),
  );

  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primaryDarkest,
    secondary: AppColors.primaryDeep,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.primaryDarkest,
    tertiary: AppColors.warning,
    onTertiary: AppColors.onPrimary,
    tertiaryContainer: AppColors.warningSoft,
    onTertiaryContainer: AppColors.ink,
    error: AppColors.danger,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.backgroundAlt,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  static ThemeData get light {
    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.primaryHover;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textSupport;
            }
            return AppColors.onPrimary;
          }),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSupportSoft,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundAlt,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium!,
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSupport,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
    );
  }
}

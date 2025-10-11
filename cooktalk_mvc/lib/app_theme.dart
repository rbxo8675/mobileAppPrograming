import 'package:flutter/material.dart';

/// Design Tokens → ColorScheme (Material 3)
class AppTheme {
  // Brand palette (requested)
  static const primarySeed = Color(0xFFFF4757); // Tomato Red
  static const secondarySeed = Color(0xFF2ED573); // Basil Green
  static const tertiarySeed = Color(0xFFFFA502); // Butter Yellow
  static const errorSeed = Color(0xFFFF3838); // Cherry Red

  static ThemeData _base(ColorScheme base) {
    // Derive role-specific schemes from seeds, preserving brightness.
    final b = base.brightness;
    final primaryScheme = ColorScheme.fromSeed(seedColor: primarySeed, brightness: b);
    final secondaryScheme = ColorScheme.fromSeed(seedColor: secondarySeed, brightness: b);
    final tertiaryScheme = ColorScheme.fromSeed(seedColor: tertiarySeed, brightness: b);
    final errorScheme = ColorScheme.fromSeed(seedColor: errorSeed, brightness: b);

    final scheme = base.copyWith(
      // Keep primary family aligned to primarySeed
      primary: primaryScheme.primary,
      onPrimary: primaryScheme.onPrimary,
      primaryContainer: primaryScheme.primaryContainer,
      onPrimaryContainer: primaryScheme.onPrimaryContainer,

      // Override secondary family from secondarySeed
      secondary: secondaryScheme.secondary,
      onSecondary: secondaryScheme.onSecondary,
      secondaryContainer: secondaryScheme.secondaryContainer,
      onSecondaryContainer: secondaryScheme.onSecondaryContainer,

      // Override tertiary family from tertiarySeed
      tertiary: tertiaryScheme.tertiary,
      onTertiary: tertiaryScheme.onTertiary,
      tertiaryContainer: tertiaryScheme.tertiaryContainer,
      onTertiaryContainer: tertiaryScheme.onTertiaryContainer,

      // Override error family from errorSeed
      error: errorScheme.error,
      onError: errorScheme.onError,
      errorContainer: errorScheme.errorContainer,
      onErrorContainer: errorScheme.onErrorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: StadiumBorder(),
      ),
      iconTheme: const IconThemeData(size: 20),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.secondaryContainer,
        deleteIconColor: scheme.onSurfaceVariant,
        disabledColor: scheme.surface,
        secondaryLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        brightness: scheme.brightness,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        titleSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        bodySmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        labelMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        labelSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  static final light = _base(
    ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.light),
  );

  static final dark = _base(
    ColorScheme.fromSeed(seedColor: primarySeed, brightness: Brightness.dark),
  );
}

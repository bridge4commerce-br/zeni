import 'package:flutter/material.dart';

import 'zeni_colors.dart';
import 'zeni_radius.dart';
import 'zeni_typography.dart';

class ZeniTheme {
  const ZeniTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ZeniColors.primary,
      brightness: Brightness.light,
      primary: ZeniColors.primary,
      secondary: ZeniColors.accent,
      surface: ZeniColors.surface,
      error: ZeniColors.error,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ZeniColors.background,
      textColor: ZeniColors.text,
      appBarBackgroundColor: ZeniColors.background,
      appBarForegroundColor: ZeniColors.text,
      inputFillColor: ZeniColors.surface,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ZeniColors.primary,
      brightness: Brightness.dark,
      primary: ZeniColors.primary,
      secondary: ZeniColors.accent,
      surface: ZeniColors.darkSurface,
      error: ZeniColors.error,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ZeniColors.darkBackground,
      textColor: ZeniColors.darkText,
      appBarBackgroundColor: ZeniColors.darkBackground,
      appBarForegroundColor: ZeniColors.darkText,
      inputFillColor: ZeniColors.darkSurface,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color textColor,
    required Color appBarBackgroundColor,
    required Color appBarForegroundColor,
    required Color inputFillColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: ZeniTypography.textTheme(textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: ZeniRadius.card),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: ZeniRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: ZeniColors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? ZeniColors.primaryDark : ZeniColors.mutedText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            color: selected ? ZeniColors.primaryDark : ZeniColors.mutedText,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ZeniColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeniRadius.md),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeniRadius.md),
          borderSide: const BorderSide(color: ZeniColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeniRadius.md),
          borderSide: const BorderSide(color: ZeniColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeniRadius.md),
          borderSide: const BorderSide(color: ZeniColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeniRadius.md),
          borderSide: const BorderSide(color: ZeniColors.error, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ZeniColors.primary;
          }

          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ZeniColors.primary.withValues(alpha: 0.34);
          }

          return null;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZeniColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: ZeniRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZeniColors.primaryDark,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          side: const BorderSide(color: ZeniColors.primary),
          shape: RoundedRectangleBorder(borderRadius: ZeniRadius.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ZeniColors.primaryDark,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

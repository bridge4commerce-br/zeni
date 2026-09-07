import 'package:flutter/material.dart';

class ZeniTypography {
  const ZeniTypography._();

  static const String fontFamily = 'Fredoka';

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

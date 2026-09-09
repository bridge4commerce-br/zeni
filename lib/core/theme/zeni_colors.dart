import 'package:flutter/material.dart';

class ZeniColors {
  const ZeniColors._();

  static const Color primary = Color(0xFF22C55E);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryLight = Color(0xFF86EFAC);
  static const Color accent = Color(0xFFFFD166);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color sky = Color(0xFF38BDF8);
  static const Color pink = Color(0xFFF472B6);

  static const Color background = Color(0xFFFDFDF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1F2937);

  static const Color darkBackground = Color(0xFF102218);
  static const Color darkSurface = Color(0xFF173322);
  static const Color darkText = Color(0xFFF8FAFC);

  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color orange = Color(0xFFF97316);
}

@immutable
class ZeniSemanticColors extends ThemeExtension<ZeniSemanticColors> {
  const ZeniSemanticColors({
    required this.brand,
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.onActionPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.borderSubtle,
    required this.accentStar,
    required this.focus,
  });

  final Color brand;
  final Color actionPrimary;
  final Color actionPrimaryPressed;
  final Color onActionPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color borderSubtle;
  final Color accentStar;
  final Color focus;

  static const light = ZeniSemanticColors(
    brand: Color(0xFF22C55E),
    actionPrimary: Color(0xFF15803D),
    actionPrimaryPressed: Color(0xFF166534),
    onActionPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF17211B),
    textSecondary: Color(0xFF526057),
    canvas: Color(0xFFF8FAF7),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF0FDF4),
    borderSubtle: Color(0xFFDDE5DF),
    accentStar: Color(0xFFFFD166),
    focus: Color(0xFF1D4ED8),
  );

  static const dark = ZeniSemanticColors(
    brand: Color(0xFF4ADE80),
    actionPrimary: Color(0xFF4ADE80),
    actionPrimaryPressed: Color(0xFF22C55E),
    onActionPrimary: Color(0xFF102218),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFC4D1C8),
    canvas: Color(0xFF102218),
    surface: Color(0xFF173322),
    surfaceSubtle: Color(0xFF1D4029),
    borderSubtle: Color(0xFF375844),
    accentStar: Color(0xFFFFD166),
    focus: Color(0xFF93C5FD),
  );

  @override
  ZeniSemanticColors copyWith({
    Color? brand,
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? onActionPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? borderSubtle,
    Color? accentStar,
    Color? focus,
  }) {
    return ZeniSemanticColors(
      brand: brand ?? this.brand,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      onActionPrimary: onActionPrimary ?? this.onActionPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accentStar: accentStar ?? this.accentStar,
      focus: focus ?? this.focus,
    );
  }

  @override
  ZeniSemanticColors lerp(covariant ZeniSemanticColors? other, double t) {
    if (other == null) return this;
    return ZeniSemanticColors(
      brand: Color.lerp(brand, other.brand, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryPressed: Color.lerp(
        actionPrimaryPressed,
        other.actionPrimaryPressed,
        t,
      )!,
      onActionPrimary: Color.lerp(onActionPrimary, other.onActionPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accentStar: Color.lerp(accentStar, other.accentStar, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
    );
  }
}

extension ZeniSemanticColorsContext on BuildContext {
  ZeniSemanticColors get zeniColors =>
      Theme.of(this).extension<ZeniSemanticColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? ZeniSemanticColors.dark
          : ZeniSemanticColors.light);
}

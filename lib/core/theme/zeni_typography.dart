import 'package:flutter/material.dart';

import '../layout/zeni_responsive.dart';

class ZeniSemanticTypography {
  const ZeniSemanticTypography({
    required this.display,
    required this.pageTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.bodyEmphasis,
    required this.metadata,
    required this.button,
    required this.chip,
  });

  final TextStyle display;
  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle bodyEmphasis;
  final TextStyle metadata;
  final TextStyle button;
  final TextStyle chip;
}

class ZeniTypography {
  const ZeniTypography._();

  static const String fontFamily = 'Fredoka';
  static const String openDyslexicFontFamily = 'OpenDyslexic';

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static ZeniSemanticTypography of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeFontFamily =
        theme.textTheme.bodyMedium?.fontFamily ?? fontFamily;

    return semanticFor(
      windowClass: ZeniResponsive.windowClass(context),
      primaryColor: theme.textTheme.bodyLarge?.color ?? colorScheme.onSurface,
      secondaryColor: colorScheme.onSurfaceVariant,
      fontFamily: activeFontFamily,
    );
  }

  static ZeniSemanticTypography semanticFor({
    required ZeniWindowClass windowClass,
    required Color primaryColor,
    required Color secondaryColor,
    String fontFamily = ZeniTypography.fontFamily,
  }) {
    final isOpenDyslexic = fontFamily == openDyslexicFontFamily;
    final headingWeight = FontWeight.w700;
    final semiboldWeight = isOpenDyslexic ? FontWeight.w700 : FontWeight.w600;
    final bodyWeight = FontWeight.w400;
    final emphasisWeight = isOpenDyslexic ? FontWeight.w400 : FontWeight.w500;
    final chipWeight = isOpenDyslexic ? FontWeight.w700 : FontWeight.w500;
    final readingHeightOffset = isOpenDyslexic ? .05 : 0;

    final displaySize = switch (windowClass) {
      ZeniWindowClass.compact => 32.0,
      ZeniWindowClass.medium => 36.0,
      ZeniWindowClass.expanded || ZeniWindowClass.large => 40.0,
    };
    final pageTitleSize = switch (windowClass) {
      ZeniWindowClass.compact => 28.0,
      ZeniWindowClass.medium => 30.0,
      ZeniWindowClass.expanded || ZeniWindowClass.large => 32.0,
    };
    final sectionTitleSize = switch (windowClass) {
      ZeniWindowClass.compact || ZeniWindowClass.medium => 22.0,
      ZeniWindowClass.expanded || ZeniWindowClass.large => 24.0,
    };

    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      required Color color,
      bool readingStyle = false,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height + (readingStyle ? readingHeightOffset : 0),
        color: color,
      );
    }

    return ZeniSemanticTypography(
      display: style(
        size: displaySize,
        weight: headingWeight,
        height: 1.1,
        color: primaryColor,
      ),
      pageTitle: style(
        size: pageTitleSize,
        weight: headingWeight,
        height: 1.15,
        color: primaryColor,
      ),
      sectionTitle: style(
        size: sectionTitleSize,
        weight: semiboldWeight,
        height: 1.22,
        color: primaryColor,
      ),
      cardTitle: style(
        size: 18,
        weight: semiboldWeight,
        height: 1.28,
        color: primaryColor,
      ),
      body: style(
        size: 16,
        weight: bodyWeight,
        height: 1.45,
        color: primaryColor,
        readingStyle: true,
      ),
      bodyEmphasis: style(
        size: 16,
        weight: emphasisWeight,
        height: 1.45,
        color: primaryColor,
        readingStyle: true,
      ),
      metadata: style(
        size: 14,
        weight: bodyWeight,
        height: 1.4,
        color: secondaryColor,
        readingStyle: true,
      ),
      button: style(
        size: 16,
        weight: semiboldWeight,
        height: 1.2,
        color: primaryColor,
      ),
      chip: style(
        size: 14,
        weight: chipWeight,
        height: 1.2,
        color: primaryColor,
      ),
    );
  }

  static TextTheme applyFontFamily(TextTheme theme, String fontFamily) {
    final isOpenDyslexic = fontFamily == openDyslexicFontFamily;

    TextStyle? apply(TextStyle? style, {required bool emphasized}) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: fontFamily,
        fontWeight: isOpenDyslexic
            ? (emphasized ? FontWeight.w700 : FontWeight.w400)
            : style.fontWeight,
        height: isOpenDyslexic && !emphasized
            ? (style.height ?? 1.4) + .05
            : style.height,
      );
    }

    return theme.copyWith(
      displayLarge: apply(theme.displayLarge, emphasized: true),
      displayMedium: apply(theme.displayMedium, emphasized: true),
      displaySmall: apply(theme.displaySmall, emphasized: true),
      headlineLarge: apply(theme.headlineLarge, emphasized: true),
      headlineMedium: apply(theme.headlineMedium, emphasized: true),
      headlineSmall: apply(theme.headlineSmall, emphasized: true),
      titleLarge: apply(theme.titleLarge, emphasized: true),
      titleMedium: apply(theme.titleMedium, emphasized: true),
      titleSmall: apply(theme.titleSmall, emphasized: true),
      bodyLarge: apply(theme.bodyLarge, emphasized: false),
      bodyMedium: apply(theme.bodyMedium, emphasized: false),
      bodySmall: apply(theme.bodySmall, emphasized: false),
      labelLarge: apply(theme.labelLarge, emphasized: true),
      labelMedium: apply(theme.labelMedium, emphasized: true),
      labelSmall: apply(theme.labelSmall, emphasized: true),
    );
  }
}

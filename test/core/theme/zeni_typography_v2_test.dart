import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/layout/zeni_responsive.dart';
import 'package:zeni/core/theme/zeni_typography.dart';

void main() {
  const primary = Color(0xFF17211B);
  const secondary = Color(0xFF526057);

  ZeniSemanticTypography typography(
    ZeniWindowClass windowClass, {
    String fontFamily = ZeniTypography.fontFamily,
  }) {
    return ZeniTypography.semanticFor(
      windowClass: windowClass,
      primaryColor: primary,
      secondaryColor: secondary,
      fontFamily: fontFamily,
    );
  }

  test('exposes every semantic typography role with final Fredoka weights', () {
    final type = typography(ZeniWindowClass.compact);

    expect(type.display.fontWeight, FontWeight.w700);
    expect(type.pageTitle.fontWeight, FontWeight.w700);
    expect(type.sectionTitle.fontWeight, FontWeight.w600);
    expect(type.cardTitle.fontWeight, FontWeight.w600);
    expect(type.body.fontWeight, FontWeight.w400);
    expect(type.bodyEmphasis.fontWeight, FontWeight.w500);
    expect(type.metadata.fontWeight, FontWeight.w400);
    expect(type.button.fontWeight, FontWeight.w600);
    expect(type.chip.fontWeight, FontWeight.w500);
    expect(type.body.fontFamily, ZeniTypography.fontFamily);
  });

  test('scales titles moderately across compact expanded and large', () {
    final compact = typography(ZeniWindowClass.compact);
    final expanded = typography(ZeniWindowClass.expanded);
    final large = typography(ZeniWindowClass.large);

    expect(compact.display.fontSize, 32);
    expect(expanded.display.fontSize, 40);
    expect(large.display.fontSize, 40);
    expect(compact.pageTitle.fontSize, 28);
    expect(expanded.pageTitle.fontSize, 32);
    expect(large.pageTitle.fontSize, 32);
    expect(compact.body.fontSize, 16);
    expect(expanded.body.fontSize, 16);
    expect(large.body.fontSize, 16);
  });

  test(
    'maps OpenDyslexic only to available weights and taller reading styles',
    () {
      final fredoka = typography(ZeniWindowClass.compact);
      final dyslexic = typography(
        ZeniWindowClass.compact,
        fontFamily: ZeniTypography.openDyslexicFontFamily,
      );

      expect(dyslexic.display.fontWeight, FontWeight.w700);
      expect(dyslexic.sectionTitle.fontWeight, FontWeight.w700);
      expect(dyslexic.body.fontWeight, FontWeight.w400);
      expect(dyslexic.bodyEmphasis.fontWeight, FontWeight.w400);
      expect(dyslexic.metadata.fontWeight, FontWeight.w400);
      expect(dyslexic.button.fontWeight, FontWeight.w700);
      expect(dyslexic.chip.fontWeight, FontWeight.w700);
      expect(dyslexic.body.height, greaterThan(fredoka.body.height!));
    },
  );

  test('accessibility override normalizes the legacy TextTheme safely', () {
    final overridden = ZeniTypography.applyFontFamily(
      ZeniTypography.textTheme(primary),
      ZeniTypography.openDyslexicFontFamily,
    );

    expect(overridden.titleLarge?.fontWeight, FontWeight.w700);
    expect(overridden.bodyLarge?.fontWeight, FontWeight.w400);
    expect(overridden.bodyMedium?.fontWeight, FontWeight.w400);
    expect(
      overridden.bodyMedium?.fontFamily,
      ZeniTypography.openDyslexicFontFamily,
    );
  });
}

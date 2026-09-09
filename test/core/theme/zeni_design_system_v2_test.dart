import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/layout/zeni_responsive.dart';
import 'package:zeni/core/theme/zeni_colors.dart';
import 'package:zeni/core/theme/zeni_radius.dart';
import 'package:zeni/core/theme/zeni_spacing.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_visual_mode.dart';

void main() {
  test('Kids and Parent share the DS with distinct expressions', () {
    final kids = ZeniVisualExpression.resolve(ZeniVisualMode.kids);
    final parent = ZeniVisualExpression.resolve(ZeniVisualMode.parent);

    expect(kids.primaryActionHeight, ZeniTouchTargets.childPriority);
    expect(parent.primaryActionHeight, ZeniTouchTargets.minimum);
    expect(kids.surfaceRadius, ZeniRadius.kidsValue);
    expect(parent.surfaceRadius, ZeniRadius.parentValue);
    expect(kids.surfacePadding, ZeniSpacing.spaceGroup);
    expect(parent.surfacePadding, ZeniSpacing.spaceCard);
    expect(kids.sectionSpacing, parent.sectionSpacing);
  });

  test('semantic spacing and radius aliases reuse the core scale', () {
    expect(ZeniSpacing.spaceInlineTight, ZeniSpacing.xs);
    expect(ZeniSpacing.spaceInline, ZeniSpacing.sm);
    expect(ZeniSpacing.spaceControl, ZeniSpacing.md);
    expect(ZeniSpacing.spaceCard, ZeniSpacing.lg);
    expect(ZeniSpacing.spaceGroup, ZeniSpacing.xl);
    expect(ZeniSpacing.spaceSection, ZeniSpacing.xxl);
    expect(ZeniSpacing.spaceHero, ZeniSpacing.xxxl);
    expect(ZeniRadius.controlValue, ZeniRadius.md);
    expect(ZeniRadius.heroValue, ZeniRadius.xl);
  });

  test('light and dark themes expose semantic colors', () {
    final light = ZeniTheme.light.extension<ZeniSemanticColors>();
    final dark = ZeniTheme.dark.extension<ZeniSemanticColors>();

    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light!.canvas, isNot(dark!.canvas));
    expect(light.textPrimary, isNot(dark.textPrimary));
    expect(light.actionPrimary, const Color(0xFF15803D));
    expect(dark.textSecondary, const Color(0xFFC4D1C8));
  });
}

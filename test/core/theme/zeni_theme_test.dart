import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/accessibility/zeni_accessibility_settings.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';

void main() {
  test('uses Fredoka as the default Zeni typeface', () {
    final theme = ZeniTheme.light;

    expect(theme.textTheme.bodyMedium?.fontFamily, ZeniTypography.fontFamily);
  });

  test('keeps OpenDyslexic as the accessibility override', () {
    const settings = ZeniAccessibilitySettings(dyslexiaFontEnabled: true);

    expect(settings.fontFamily, 'OpenDyslexic');
    expect(
      ZeniTheme.light.textTheme
          .apply(fontFamily: settings.fontFamily)
          .bodyMedium
          ?.fontFamily,
      'OpenDyslexic',
    );
  });
}

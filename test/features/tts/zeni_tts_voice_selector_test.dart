import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/tts/domain/zeni_tts_voice_selector.dart';

void main() {
  ZeniTtsVoice voice({
    String? name,
    String? locale,
    String? identifier,
    int? quality,
    bool? networkRequired,
  }) {
    return ZeniTtsVoice(
      name: name,
      locale: locale,
      identifier: identifier,
      quality: quality,
      networkRequired: networkRequired,
    );
  }

  test('normalizes BCP-47 separators and casing', () {
    expect(ZeniTtsLocale.normalize('PT_br'), 'pt-BR');
    expect(ZeniTtsLocale.normalize('es-419'), 'es-419');
    expect(ZeniTtsLocale.normalize('ja_jp'), 'ja-JP');
  });

  test('exact locale wins over another regional voice', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [
        voice(name: 'Portugal', locale: 'pt-PT', quality: 9),
        voice(name: 'Brasil', locale: 'pt_BR', quality: 1),
      ],
      requestedLocale: 'pt-BR',
      platform: ZeniTtsPlatformKind.apple,
    );

    expect(selected?.name, 'Brasil');
  });

  test('Android prefers an offline exact voice over higher online quality', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [
        voice(
          name: 'Online',
          locale: 'pt-BR',
          quality: 100,
          networkRequired: true,
        ),
        voice(
          name: 'Offline',
          locale: 'pt-BR',
          quality: 20,
          networkRequired: false,
        ),
      ],
      requestedLocale: 'pt-BR',
      platform: ZeniTtsPlatformKind.android,
    );

    expect(selected?.name, 'Offline');
  });

  test('Android uses quality among comparable offline voices', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [
        voice(name: 'Low', locale: 'pt-BR', quality: 1, networkRequired: false),
        voice(
          name: 'High',
          locale: 'pt-BR',
          quality: 2,
          networkRequired: false,
        ),
      ],
      requestedLocale: 'pt-BR',
      platform: ZeniTtsPlatformKind.android,
    );

    expect(selected?.name, 'High');
  });

  test('Apple uses quality among exact locale voices', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [
        voice(name: 'Low', locale: 'pt-BR', quality: 1),
        voice(name: 'High', locale: 'pt-BR', quality: 2),
      ],
      requestedLocale: 'pt-BR',
      platform: ZeniTtsPlatformKind.apple,
    );

    expect(selected?.name, 'High');
  });

  test('tie breaking is stable regardless of voice order', () {
    final first = voice(
      name: 'First',
      locale: 'en-US',
      identifier: 'a',
      quality: 1,
    );
    final second = voice(
      name: 'Second',
      locale: 'en-US',
      identifier: 'b',
      quality: 1,
    );

    final selectedForward = ZeniTtsVoiceSelector.select(
      voices: [second, first],
      requestedLocale: 'en-US',
      platform: ZeniTtsPlatformKind.apple,
    );
    final selectedReverse = ZeniTtsVoiceSelector.select(
      voices: [first, second],
      requestedLocale: 'en-US',
      platform: ZeniTtsPlatformKind.apple,
    );

    expect(selectedForward?.identifier, 'a');
    expect(selectedReverse?.identifier, 'a');
  });

  test(
    'falls back to the same language when a regional locale is unavailable',
    () {
      final selected = ZeniTtsVoiceSelector.select(
        voices: [voice(name: 'Spanish', locale: 'es-ES', quality: 1)],
        requestedLocale: 'es-MX',
        platform: ZeniTtsPlatformKind.android,
      );

      expect(selected?.locale, 'es-ES');
    },
  );

  test('returns no voice when no matching language is available', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [voice(name: 'German', locale: 'de-DE')],
      requestedLocale: 'ja-JP',
      platform: ZeniTtsPlatformKind.apple,
    );

    expect(selected, isNull);
  });

  test('handles incomplete metadata and unknown network state safely', () {
    final selected = ZeniTtsVoiceSelector.select(
      voices: [
        voice(locale: 'fr-FR'),
        voice(name: 'French', locale: 'fr-FR', networkRequired: null),
      ],
      requestedLocale: 'fr-FR',
      platform: ZeniTtsPlatformKind.android,
    );

    expect(selected?.name, 'French');
  });
}

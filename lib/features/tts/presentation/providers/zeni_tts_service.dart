import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../domain/zeni_tts_voice_selector.dart';

class ZeniTtsSpeakResult {
  const ZeniTtsSpeakResult({required this.didSpeak, this.message});

  const ZeniTtsSpeakResult.spoken() : this(didSpeak: true);

  const ZeniTtsSpeakResult.skipped(String message)
    : this(didSpeak: false, message: message);

  final bool didSpeak;
  final String? message;
}

class ZeniTtsSpeechConfiguration {
  const ZeniTtsSpeechConfiguration._();

  // Native engines scale rate differently, so these values stay centralized
  // for calibration without changing the speech flow.
  static const speechRate = 0.42;
  static const pitch = 1.0;
  static const volume = 1.0;
}

abstract class ZeniTtsPlatform {
  ZeniTtsPlatformKind get platformKind;

  Future<void> stop();

  Future<List<String>> getLanguages();

  Future<List<ZeniTtsVoice>> getVoices();

  Future<void> setLanguage(String language);

  Future<void> setVoice(ZeniTtsVoice voice);

  Future<void> setSpeechRate(double rate);

  Future<void> setPitch(double pitch);

  Future<void> setVolume(double volume);

  Future<void> speak(String text);
}

class FlutterZeniTtsPlatform implements ZeniTtsPlatform {
  FlutterZeniTtsPlatform() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  @override
  ZeniTtsPlatformKind get platformKind {
    if (kIsWeb) return ZeniTtsPlatformKind.other;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ZeniTtsPlatformKind.android,
      TargetPlatform.iOS || TargetPlatform.macOS => ZeniTtsPlatformKind.apple,
      _ => ZeniTtsPlatformKind.other,
    };
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.awaitSpeakCompletion(false);
    _configured = true;
  }

  @override
  Future<void> setLanguage(String language) async {
    await _ensureConfigured();
    await _tts.setLanguage(language);
  }

  @override
  Future<List<String>> getLanguages() async {
    await _ensureConfigured();
    final languages = await _tts.getLanguages;
    if (languages is! Iterable) return const [];
    return languages.whereType<String>().toList();
  }

  @override
  Future<List<ZeniTtsVoice>> getVoices() async {
    await _ensureConfigured();
    final voices = await _tts.getVoices;
    if (voices is! Iterable) return const [];

    return voices.whereType<Map>().map((voice) {
      final name = voice['name'];
      final locale = voice['locale'];
      return ZeniTtsVoice(
        name: name is String ? name : null,
        locale: locale is String ? locale : null,
        identifier: voice['identifier'] is String
            ? voice['identifier'] as String
            : null,
        quality: voice['quality'] is num
            ? (voice['quality'] as num).toInt()
            : null,
        networkRequired: voice['network_required'] is bool
            ? voice['network_required'] as bool
            : null,
      );
    }).toList();
  }

  @override
  Future<void> setVoice(ZeniTtsVoice voice) async {
    await _ensureConfigured();
    await _tts.setVoice({'name': voice.name!, 'locale': voice.locale!});
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _ensureConfigured();
    await _tts.setPitch(pitch);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _ensureConfigured();
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _ensureConfigured();
    await _tts.setVolume(volume);
  }

  @override
  Future<void> speak(String text) async {
    await _ensureConfigured();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _ensureConfigured();
    await _tts.stop();
  }
}

final zeniTtsPlatformProvider = Provider<ZeniTtsPlatform>((ref) {
  return FlutterZeniTtsPlatform();
});

final zeniTtsServiceProvider = Provider<ZeniTtsService>((ref) {
  final settings =
      ref.watch(zeniAppStateControllerProvider).asData?.value.appSettings ??
      const AppSettings();
  final platform = ref.watch(zeniTtsPlatformProvider);
  return ZeniTtsService(settings: settings, platform: platform);
});

class ZeniTtsService {
  ZeniTtsService({
    required AppSettings settings,
    required ZeniTtsPlatform platform,
  }) : _platform = platform;

  final ZeniTtsPlatform _platform;
  int _speechRequest = 0;

  bool isEnabledForChild(ChildProfile child) => true;

  String disabledMessageForChild(ChildProfile child) =>
      'A leitura em voz alta não está disponível agora.';

  Future<ZeniTtsSpeakResult> speakForChild({
    required ChildProfile child,
    required String title,
    String? description,
    required String locale,
  }) async {
    final text = [
      title.trim(),
      if (description != null && description.trim().isNotEmpty)
        description.trim(),
    ].join('. ');
    return speakTextForChild(child: child, text: text, locale: locale);
  }

  Future<ZeniTtsSpeakResult> speakTextForChild({
    required ChildProfile child,
    required String text,
    required String locale,
  }) async {
    if (text.trim().isEmpty) {
      return const ZeniTtsSpeakResult.skipped(
        'Não há texto disponível para ouvir agora.',
      );
    }

    final request = ++_speechRequest;

    try {
      await _platform.stop();
      if (request != _speechRequest) {
        return const ZeniTtsSpeakResult.skipped(
          'A leitura foi substituída por uma nova.',
        );
      }
      await _configureSpeech(locale);
      if (request != _speechRequest) {
        return const ZeniTtsSpeakResult.skipped(
          'A leitura foi substituída por uma nova.',
        );
      }
      await _platform.speak(text);
      return const ZeniTtsSpeakResult.spoken();
    } catch (_) {
      return const ZeniTtsSpeakResult.skipped(
        'Não foi possível reproduzir o áudio agora.',
      );
    }
  }

  Future<void> stop() async {
    _speechRequest++;
    try {
      await _platform.stop();
    } catch (_) {
      // Leaving the detail must never block navigation if the native engine
      // is already unavailable.
    }
  }

  Future<void> _configureSpeech(String requestedLocale) async {
    final normalizedLocale = ZeniTtsLocale.normalize(requestedLocale);
    final languages = await _safeLanguages();
    final locale = _preferredLanguage(languages, normalizedLocale);
    await _tryConfigure(
      () => _platform.setLanguage(locale ?? normalizedLocale),
    );

    final voices = await _safeVoices();
    final voice = ZeniTtsVoiceSelector.select(
      voices: voices,
      requestedLocale: normalizedLocale,
      platform: _platform.platformKind,
    );
    if (voice != null) {
      await _tryConfigure(() => _platform.setVoice(voice));
    }

    _debugVoiceSelection(
      requestedLocale: normalizedLocale,
      selectedVoice: voice,
    );

    await _tryConfigure(
      () => _platform.setSpeechRate(ZeniTtsSpeechConfiguration.speechRate),
    );
    await _tryConfigure(
      () => _platform.setPitch(ZeniTtsSpeechConfiguration.pitch),
    );
    await _tryConfigure(
      () => _platform.setVolume(ZeniTtsSpeechConfiguration.volume),
    );
  }

  Future<void> _tryConfigure(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // The platform's default remains usable when an optional native setting
      // is unavailable on a simulator or a specific device.
    }
  }

  Future<List<String>> _safeLanguages() async {
    try {
      return await _platform.getLanguages();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ZeniTtsVoice>> _safeVoices() async {
    try {
      return await _platform.getVoices();
    } catch (_) {
      return const [];
    }
  }

  String? _preferredLanguage(List<String> languages, String requestedLocale) {
    for (final language in languages) {
      if (ZeniTtsLocale.normalize(language) == requestedLocale) {
        return language;
      }
    }
    for (final language in languages) {
      if (ZeniTtsLocale.languageCode(language) ==
          ZeniTtsLocale.languageCode(requestedLocale)) {
        return language;
      }
    }
    return null;
  }

  void _debugVoiceSelection({
    required String requestedLocale,
    required ZeniTtsVoice? selectedVoice,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ZeniTTS] platform=${_platform.platformKind.name} '
      'requestedLocale=$requestedLocale '
      'selectedLocale=${selectedVoice?.locale ?? 'default'} '
      'name=${selectedVoice?.name ?? 'default'} '
      'identifier=${selectedVoice?.identifier ?? 'none'} '
      'quality=${selectedVoice?.quality?.toString() ?? 'unknown'} '
      'offline=${selectedVoice?.networkRequired == null ? 'unknown' : !selectedVoice!.networkRequired!} '
      'rate=${ZeniTtsSpeechConfiguration.speechRate} '
      'pitch=${ZeniTtsSpeechConfiguration.pitch}',
    );
  }
}

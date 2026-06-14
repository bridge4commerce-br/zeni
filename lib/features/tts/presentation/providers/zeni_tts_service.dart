import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../settings/data/models/app_settings.dart';

class ZeniTtsSpeakResult {
  const ZeniTtsSpeakResult({required this.didSpeak, this.message});

  const ZeniTtsSpeakResult.spoken() : this(didSpeak: true);

  const ZeniTtsSpeakResult.skipped(String message)
    : this(didSpeak: false, message: message);

  final bool didSpeak;
  final String? message;
}

abstract class ZeniTtsPlatform {
  Future<void> stop();

  Future<void> setLanguage(String language);

  Future<void> setSpeechRate(double rate);

  Future<void> setPitch(double pitch);

  Future<void> speak(String text);
}

class FlutterZeniTtsPlatform implements ZeniTtsPlatform {
  FlutterZeniTtsPlatform() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

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
  const ZeniTtsService({
    required AppSettings settings,
    required ZeniTtsPlatform platform,
  }) : _settings = settings,
       _platform = platform;

  final AppSettings _settings;
  final ZeniTtsPlatform _platform;

  bool isEnabledForChild(ChildProfile child) {
    if (_settings.readAloudByChildProfile) {
      return child.ttsEnabled;
    }
    return _settings.ttsEnabled;
  }

  String disabledMessageForChild(ChildProfile child) {
    if (_settings.readAloudByChildProfile) {
      return 'A leitura em voz alta está desativada no perfil de ${child.name}.';
    }
    return 'A leitura em voz alta está desativada nos ajustes do app.';
  }

  Future<ZeniTtsSpeakResult> speakForChild({
    required ChildProfile child,
    required String title,
    String? description,
  }) async {
    if (!isEnabledForChild(child)) {
      return ZeniTtsSpeakResult.skipped(disabledMessageForChild(child));
    }

    final text = [
      title.trim(),
      if (description != null && description.trim().isNotEmpty)
        description.trim(),
    ].join('. ');
    if (text.trim().isEmpty) {
      return const ZeniTtsSpeakResult.skipped(
        'Não há texto disponível para ouvir agora.',
      );
    }

    await _platform.stop();
    await _platform.setLanguage('pt-BR');
    await _platform.setSpeechRate(0.45);
    await _platform.setPitch(1.0);
    await _platform.speak(text);
    return const ZeniTtsSpeakResult.spoken();
  }
}

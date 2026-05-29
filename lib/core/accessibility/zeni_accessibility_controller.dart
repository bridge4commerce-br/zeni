import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/models/app_settings.dart';
import '../state/zeni_app_state_controller.dart';
import 'zeni_accessibility_settings.dart';

final zeniAccessibilityControllerProvider =
    Provider<ZeniAccessibilityController>((ref) {
      final appState = ref.watch(zeniAppStateControllerProvider).asData?.value;
      final settings = ZeniAccessibilitySettings.fromAppSettings(
        appState?.appSettings ?? const AppSettings(),
      );

      return ZeniAccessibilityController(ref: ref, settings: settings);
    });

class ZeniAccessibilityController {
  const ZeniAccessibilityController({required Ref ref, required this.settings})
    : _ref = ref;

  final Ref _ref;
  final ZeniAccessibilitySettings settings;

  Future<void> setThemeModeOption(ZeniThemeModeOption value) {
    return _updateAppSettings(
      (current) => current.copyWith(themeMode: value.name),
    );
  }

  Future<void> setDyslexiaFontEnabled(bool value) {
    return _updateAppSettings(
      (current) => current.copyWith(dyslexiaFontEnabled: value),
    );
  }

  Future<void> setTextScale(double value) {
    final safeValue = value.clamp(0.85, 1.35).toDouble();

    return _updateAppSettings(
      (current) => current.copyWith(textScale: safeValue),
    );
  }

  Future<void> setVibrationEnabled(bool value) {
    return _updateAppSettings(
      (current) => current.copyWith(vibrationEnabled: value),
    );
  }

  Future<void> setNotificationsEnabled(bool value) {
    return _updateAppSettings(
      (current) => current.copyWith(notificationsEnabled: value),
    );
  }

  Future<void> setTtsEnabled(bool value) {
    return _updateAppSettings((current) => current.copyWith(ttsEnabled: value));
  }

  Future<void> setReadAloudByChildProfile(bool value) {
    return _updateAppSettings(
      (current) => current.copyWith(readAloudByChildProfile: value),
    );
  }

  Future<void> _updateAppSettings(
    AppSettings Function(AppSettings current) update,
  ) async {
    final currentAppState = await _ref.read(
      zeniAppStateControllerProvider.future,
    );
    final nextSettings = update(currentAppState.appSettings);
    await _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(nextSettings);
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/models/app_settings.dart';
import '../state/zeni_app_state_controller.dart';

abstract class ZeniHapticsPlatform {
  Future<void> lightImpact();

  Future<void> mediumImpact();

  Future<void> heavyImpact();

  Future<void> selectionClick();

  Future<void> vibrate();
}

class SystemZeniHapticsPlatform implements ZeniHapticsPlatform {
  const SystemZeniHapticsPlatform();

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  @override
  Future<void> lightImpact() => HapticFeedback.lightImpact();

  @override
  Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  @override
  Future<void> selectionClick() => HapticFeedback.selectionClick();

  @override
  Future<void> vibrate() => HapticFeedback.vibrate();
}

final zeniHapticsPlatformProvider = Provider<ZeniHapticsPlatform>((ref) {
  return const SystemZeniHapticsPlatform();
});

final zeniHapticsProvider = Provider<ZeniHaptics>((ref) {
  final settings =
      ref.watch(zeniAppStateControllerProvider).asData?.value.appSettings ??
      const AppSettings();
  final platform = ref.watch(zeniHapticsPlatformProvider);
  return ZeniHaptics(settings: settings, platform: platform);
});

class ZeniHaptics {
  const ZeniHaptics({
    required AppSettings settings,
    required ZeniHapticsPlatform platform,
  }) : _settings = settings,
       _platform = platform;

  final AppSettings _settings;
  final ZeniHapticsPlatform _platform;

  bool get isEnabled => _settings.vibrationEnabled;

  Future<void> selection() => _run(_platform.selectionClick);

  Future<void> confirm() => _run(_platform.mediumImpact);

  Future<void> celebrate() => _run(_platform.heavyImpact);

  Future<void> cancel() => _run(_platform.lightImpact);

  Future<void> warn() => _run(_platform.vibrate);

  Future<void> _run(Future<void> Function() action) async {
    if (!isEnabled) return;
    try {
      await action();
    } catch (_) {
      // Haptics are optional feedback and must never block the core flow.
    }
  }
}

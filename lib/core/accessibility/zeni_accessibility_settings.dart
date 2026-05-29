import 'package:flutter/material.dart';

import '../../features/settings/data/models/app_settings.dart';

enum ZeniThemeModeOption { system, light, dark }

extension ZeniThemeModeOptionX on ZeniThemeModeOption {
  ThemeMode get materialThemeMode {
    return switch (this) {
      ZeniThemeModeOption.system => ThemeMode.system,
      ZeniThemeModeOption.light => ThemeMode.light,
      ZeniThemeModeOption.dark => ThemeMode.dark,
    };
  }

  String get label {
    return switch (this) {
      ZeniThemeModeOption.system => 'Automático',
      ZeniThemeModeOption.light => 'Claro',
      ZeniThemeModeOption.dark => 'Escuro',
    };
  }

  String get description {
    return switch (this) {
      ZeniThemeModeOption.system => 'Seguir configuração do dispositivo',
      ZeniThemeModeOption.light => 'Usar sempre tema claro',
      ZeniThemeModeOption.dark => 'Usar sempre tema escuro',
    };
  }
}

class ZeniAccessibilitySettings {
  const ZeniAccessibilitySettings({
    this.themeModeOption = ZeniThemeModeOption.system,
    this.dyslexiaFontEnabled = false,
    this.textScale = 1.0,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.ttsEnabled = false,
    this.readAloudByChildProfile = false,
  });

  final ZeniThemeModeOption themeModeOption;
  final bool dyslexiaFontEnabled;
  final double textScale;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool ttsEnabled;
  final bool readAloudByChildProfile;

  String? get fontFamily => dyslexiaFontEnabled ? 'OpenDyslexic' : null;

  ThemeMode get themeMode => themeModeOption.materialThemeMode;

  factory ZeniAccessibilitySettings.fromAppSettings(AppSettings settings) {
    final themeModeOption = ZeniThemeModeOption.values.firstWhere(
      (option) => option.name == settings.themeMode,
      orElse: () => ZeniThemeModeOption.system,
    );

    return ZeniAccessibilitySettings(
      themeModeOption: themeModeOption,
      dyslexiaFontEnabled: settings.dyslexiaFontEnabled,
      textScale: settings.textScale,
      vibrationEnabled: settings.vibrationEnabled,
      notificationsEnabled: settings.notificationsEnabled,
      ttsEnabled: settings.ttsEnabled,
      readAloudByChildProfile: settings.readAloudByChildProfile,
    );
  }

  ZeniAccessibilitySettings copyWith({
    ZeniThemeModeOption? themeModeOption,
    bool? dyslexiaFontEnabled,
    double? textScale,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? ttsEnabled,
    bool? readAloudByChildProfile,
  }) {
    return ZeniAccessibilitySettings(
      themeModeOption: themeModeOption ?? this.themeModeOption,
      dyslexiaFontEnabled: dyslexiaFontEnabled ?? this.dyslexiaFontEnabled,
      textScale: textScale ?? this.textScale,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      readAloudByChildProfile:
          readAloudByChildProfile ?? this.readAloudByChildProfile,
    );
  }
}

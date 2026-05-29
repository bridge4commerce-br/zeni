import '../../../../core/security/parent_pin_security.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = 'system',
    this.dyslexiaFontEnabled = false,
    this.textScale = 1.0,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.ttsEnabled = false,
    this.readAloudByChildProfile = false,
    this.hasCompletedOnboarding = false,
    this.parentPin,
    this.parentPinHash,
    this.parentPinSalt,
    this.parentBiometricsEnabled = false,
    this.lastChildrenSyncAt,
    this.lastMissionsSyncAt,
    this.lastRewardsSyncAt,
    this.lastMissionLogsSyncAt,
    this.lastRewardRequestsSyncAt,
    this.lastStarLedgerSyncAt,
    this.lastFullSyncAt,
  });

  final String themeMode;
  final bool dyslexiaFontEnabled;
  final double textScale;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool ttsEnabled;
  final bool readAloudByChildProfile;
  final bool hasCompletedOnboarding;
  final String? parentPin;
  final String? parentPinHash;
  final String? parentPinSalt;
  final bool parentBiometricsEnabled;
  final DateTime? lastChildrenSyncAt;
  final DateTime? lastMissionsSyncAt;
  final DateTime? lastRewardsSyncAt;
  final DateTime? lastMissionLogsSyncAt;
  final DateTime? lastRewardRequestsSyncAt;
  final DateTime? lastStarLedgerSyncAt;
  final DateTime? lastFullSyncAt;

  bool get hasParentPin {
    return (parentPinHash?.isNotEmpty ?? false) &&
            (parentPinSalt?.isNotEmpty ?? false) ||
        (parentPin ?? '').length == 4;
  }

  bool matchesParentPin(String pin) {
    if (ParentPinSecurity.verify(
      pin: pin,
      hash: parentPinHash,
      salt: parentPinSalt,
    )) {
      return true;
    }

    return parentPin == pin;
  }

  AppSettings copyWith({
    String? themeMode,
    bool? dyslexiaFontEnabled,
    double? textScale,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? ttsEnabled,
    bool? readAloudByChildProfile,
    bool? hasCompletedOnboarding,
    String? parentPin,
    String? parentPinHash,
    String? parentPinSalt,
    bool clearParentPin = false,
    bool? parentBiometricsEnabled,
    DateTime? lastChildrenSyncAt,
    DateTime? lastMissionsSyncAt,
    DateTime? lastRewardsSyncAt,
    DateTime? lastMissionLogsSyncAt,
    DateTime? lastRewardRequestsSyncAt,
    DateTime? lastStarLedgerSyncAt,
    DateTime? lastFullSyncAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      dyslexiaFontEnabled: dyslexiaFontEnabled ?? this.dyslexiaFontEnabled,
      textScale: textScale ?? this.textScale,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      readAloudByChildProfile:
          readAloudByChildProfile ?? this.readAloudByChildProfile,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      parentPin: clearParentPin ? null : parentPin ?? this.parentPin,
      parentPinHash: clearParentPin
          ? parentPinHash
          : parentPinHash ?? this.parentPinHash,
      parentPinSalt: clearParentPin
          ? parentPinSalt
          : parentPinSalt ?? this.parentPinSalt,
      parentBiometricsEnabled:
          parentBiometricsEnabled ?? this.parentBiometricsEnabled,
      lastChildrenSyncAt: lastChildrenSyncAt ?? this.lastChildrenSyncAt,
      lastMissionsSyncAt: lastMissionsSyncAt ?? this.lastMissionsSyncAt,
      lastRewardsSyncAt: lastRewardsSyncAt ?? this.lastRewardsSyncAt,
      lastMissionLogsSyncAt:
          lastMissionLogsSyncAt ?? this.lastMissionLogsSyncAt,
      lastRewardRequestsSyncAt:
          lastRewardRequestsSyncAt ?? this.lastRewardRequestsSyncAt,
      lastStarLedgerSyncAt: lastStarLedgerSyncAt ?? this.lastStarLedgerSyncAt,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'dyslexiaFontEnabled': dyslexiaFontEnabled,
      'textScale': textScale,
      'vibrationEnabled': vibrationEnabled,
      'notificationsEnabled': notificationsEnabled,
      'ttsEnabled': ttsEnabled,
      'readAloudByChildProfile': readAloudByChildProfile,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'parentPinHash': parentPinHash,
      'parentPinSalt': parentPinSalt,
      'parentBiometricsEnabled': parentBiometricsEnabled,
      'lastChildrenSyncAt': lastChildrenSyncAt?.toIso8601String(),
      'lastMissionsSyncAt': lastMissionsSyncAt?.toIso8601String(),
      'lastRewardsSyncAt': lastRewardsSyncAt?.toIso8601String(),
      'lastMissionLogsSyncAt': lastMissionLogsSyncAt?.toIso8601String(),
      'lastRewardRequestsSyncAt': lastRewardRequestsSyncAt?.toIso8601String(),
      'lastStarLedgerSyncAt': lastStarLedgerSyncAt?.toIso8601String(),
      'lastFullSyncAt': lastFullSyncAt?.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      dyslexiaFontEnabled: json['dyslexiaFontEnabled'] as bool? ?? false,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      ttsEnabled: json['ttsEnabled'] as bool? ?? false,
      readAloudByChildProfile:
          json['readAloudByChildProfile'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      parentPin: json['parentPin'] as String?,
      parentPinHash: json['parentPinHash'] as String?,
      parentPinSalt: json['parentPinSalt'] as String?,
      parentBiometricsEnabled:
          json['parentBiometricsEnabled'] as bool? ?? false,
      lastChildrenSyncAt: json['lastChildrenSyncAt'] == null
          ? null
          : DateTime.parse(json['lastChildrenSyncAt'] as String),
      lastMissionsSyncAt: json['lastMissionsSyncAt'] == null
          ? null
          : DateTime.parse(json['lastMissionsSyncAt'] as String),
      lastRewardsSyncAt: json['lastRewardsSyncAt'] == null
          ? null
          : DateTime.parse(json['lastRewardsSyncAt'] as String),
      lastMissionLogsSyncAt: json['lastMissionLogsSyncAt'] == null
          ? null
          : DateTime.parse(json['lastMissionLogsSyncAt'] as String),
      lastRewardRequestsSyncAt: json['lastRewardRequestsSyncAt'] == null
          ? null
          : DateTime.parse(json['lastRewardRequestsSyncAt'] as String),
      lastStarLedgerSyncAt: json['lastStarLedgerSyncAt'] == null
          ? null
          : DateTime.parse(json['lastStarLedgerSyncAt'] as String),
      lastFullSyncAt: json['lastFullSyncAt'] == null
          ? null
          : DateTime.parse(json['lastFullSyncAt'] as String),
    );
  }
}

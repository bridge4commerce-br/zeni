import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/accessibility/zeni_accessibility_settings.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/supabase/zeni_supabase.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/presentation/providers/zeni_auth_providers.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_settings_tab.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/sync/data/models/cloud_consistency_diagnostic.dart';
import 'package:zeni/features/sync/data/models/device_bootstrap_result.dart';
import 'package:zeni/features/sync/data/models/historical_restore_result.dart';
import 'package:zeni/features/sync/presentation/providers/cloud_sync_providers.dart';

Future<void> enableSupabaseForTests() {
  return ZeniSupabaseBootstrap.initialize(
    config: const ZeniSupabaseConfig(
      url: 'https://zeni.test.supabase.co',
      anonKey: 'anon-key',
    ),
    initializeOverride: ({required url, required anonKey}) async {},
  );
}

Future<void> openParentSettings(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Entrar como responsável'), 300);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar como responsável'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ajustes').last);
  await tester.pumpAndSettle();
}

void seedMockAppState() {
  SharedPreferences.setMockInitialValues({
    'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
  });
}

void seedMockAppStateWith(ZeniAppState state) {
  SharedPreferences.setMockInitialValues({
    'zeni_app_state_v1': jsonEncode(state.toJson()),
  });
}

Widget buildStaticSettingsHarness({
  required ZeniAuthState authState,
  String parentDisplayName = 'Responsável',
  AppSettings appSettings = const AppSettings(),
  bool isSupabaseConfigured = true,
  ZeniSupabaseBootstrapState supabaseBootstrapState =
      const ZeniSupabaseBootstrapState.initialized(),
  bool isGoogleSignInAvailable = true,
  bool isAppleSignInAvailable = false,
  RemoteFamilySummary? remoteFamilySummary,
  Future<ZeniUpdateRemoteFamilyResult> Function({
    required String familyId,
    required String name,
  })?
  onUpdateRemoteFamilyName,
  int localChildrenCount = 2,
  int? remoteChildrenCount,
  int localMissionsCount = 3,
  int? remoteMissionsCount,
  int localRewardsCount = 2,
  int? remoteRewardsCount,
  int localMissionLogsCount = 0,
  int? remoteMissionLogsCount,
  int localRewardRequestsCount = 0,
  int? remoteRewardRequestsCount,
  int localStarLedgerCount = 0,
  int? remoteStarLedgerCount,
  List<ChildBalanceDiagnostic> childBalanceDiagnostics =
      const <ChildBalanceDiagnostic>[],
  bool hasRemoteChildBalanceData = false,
  CloudConsistencyDiagnostic? cloudConsistencyDiagnostic,
  String? cloudConsistencyErrorText,
  Future<ZeniCloudSyncResult> Function()? onSyncCloudData,
  bool showDeviceBootstrapStatus = false,
  bool showDeviceBootstrapAction = false,
  bool canRunDeviceBootstrap = false,
  String? deviceBootstrapMessage,
  Future<DeviceBootstrapResult> Function()? onDeviceBootstrap,
  bool showHistoricalRestoreStatus = false,
  bool showHistoricalRestoreAction = false,
  bool canRunHistoricalRestore = false,
  String? historicalRestoreMessage,
  Future<HistoricalRestoreResult> Function()? onHistoricalRestore,
  VoidCallback? onManageAccountAndData,
  Future<void> Function()? onClearLocalDeviceData,
  Future<void> Function(String name)? onUpdateParentDisplayName,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ParentSettingsTab(
        parentDisplayName: parentDisplayName,
        appSettings: appSettings,
        accessibilitySettings: const ZeniAccessibilitySettings(),
        onThemeModeChanged: (_) {},
        onDyslexiaFontChanged: (_) {},
        onTextScaleChanged: (_) {},
        onVibrationChanged: (_) {},
        onNotificationsChanged: (_) {},
        onTtsChanged: (_) {},
        onReadAloudByChildProfileChanged: (_) {},
        onConfigurePin: () {},
        onBiometricsChanged: (_) {},
        authState: authState,
        remoteFamilySummary: remoteFamilySummary,
        localChildrenCount: localChildrenCount,
        remoteChildrenCount: remoteChildrenCount,
        localMissionsCount: localMissionsCount,
        remoteMissionsCount: remoteMissionsCount,
        localRewardsCount: localRewardsCount,
        remoteRewardsCount: remoteRewardsCount,
        localMissionLogsCount: localMissionLogsCount,
        remoteMissionLogsCount: remoteMissionLogsCount,
        localRewardRequestsCount: localRewardRequestsCount,
        remoteRewardRequestsCount: remoteRewardRequestsCount,
        localStarLedgerCount: localStarLedgerCount,
        remoteStarLedgerCount: remoteStarLedgerCount,
        childBalanceDiagnostics: childBalanceDiagnostics,
        hasRemoteChildBalanceData: hasRemoteChildBalanceData,
        cloudConsistencyDiagnostic: cloudConsistencyDiagnostic,
        cloudConsistencyErrorText: cloudConsistencyErrorText,
        lastChildrenSyncAt: appSettings.lastChildrenSyncAt,
        lastMissionsSyncAt: appSettings.lastMissionsSyncAt,
        lastRewardsSyncAt: appSettings.lastRewardsSyncAt,
        lastMissionLogsSyncAt: appSettings.lastMissionLogsSyncAt,
        lastRewardRequestsSyncAt: appSettings.lastRewardRequestsSyncAt,
        lastStarLedgerSyncAt: appSettings.lastStarLedgerSyncAt,
        lastFullSyncAt: appSettings.lastFullSyncAt,
        isSupabaseConfigured: isSupabaseConfigured,
        supabaseBootstrapState: supabaseBootstrapState,
        isGoogleSignInAvailable: isGoogleSignInAvailable,
        isAppleSignInAvailable: isAppleSignInAvailable,
        showHistoricalRestoreStatus: showHistoricalRestoreStatus,
        showDeviceBootstrapStatus: showDeviceBootstrapStatus,
        showDeviceBootstrapAction: showDeviceBootstrapAction,
        canRunDeviceBootstrap: canRunDeviceBootstrap,
        deviceBootstrapMessage: deviceBootstrapMessage,
        showHistoricalRestoreAction: showHistoricalRestoreAction,
        canRunHistoricalRestore: canRunHistoricalRestore,
        historicalRestoreMessage: historicalRestoreMessage,
        onOpenAccount: () {},
        onSignOut: () {},
        onManageAccountAndData: onManageAccountAndData ?? () {},
        onClearLocalDeviceData: onClearLocalDeviceData ?? () async {},
        onUpdateParentDisplayName: onUpdateParentDisplayName ?? (name) async {},
        onUpdateRemoteFamilyName:
            onUpdateRemoteFamilyName ??
            ({required familyId, required name}) async =>
                const ZeniUpdateRemoteFamilyResult.failure('indisponível'),
        onSyncCloudData:
            onSyncCloudData ??
            () async => const ZeniCloudSyncResult.failure('indisponível'),
        onDeviceBootstrap:
            onDeviceBootstrap ??
            () async => const DeviceBootstrapResult.failure('indisponível'),
        onHistoricalRestore:
            onHistoricalRestore ??
            () async => const HistoricalRestoreResult.failure(
              status: HistoricalRestoreResultStatus.applyBlocked,
              message: 'indisponível',
            ),
      ),
    ),
  );
}

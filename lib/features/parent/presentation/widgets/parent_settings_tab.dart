import 'package:flutter/material.dart';

import '../../../../core/accessibility/zeni_accessibility_settings.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/inputs/counter_stepper.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../auth/data/repositories/zeni_account_repository.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../sync/data/models/cloud_consistency_diagnostic.dart';
import '../../../sync/data/models/historical_restore_result.dart';
import '../../../sync/presentation/providers/cloud_sync_providers.dart';

class ParentSettingsTab extends StatelessWidget {
  const ParentSettingsTab({
    super.key,
    required this.appSettings,
    required this.accessibilitySettings,
    required this.onThemeModeChanged,
    required this.onDyslexiaFontChanged,
    required this.onTextScaleChanged,
    required this.onVibrationChanged,
    required this.onNotificationsChanged,
    required this.onTtsChanged,
    required this.onReadAloudByChildProfileChanged,
    required this.onConfigurePin,
    required this.onBiometricsChanged,
    required this.authState,
    required this.remoteFamilySummary,
    required this.localChildrenCount,
    required this.remoteChildrenCount,
    required this.localMissionsCount,
    required this.remoteMissionsCount,
    required this.localRewardsCount,
    required this.remoteRewardsCount,
    required this.localMissionLogsCount,
    required this.remoteMissionLogsCount,
    required this.localRewardRequestsCount,
    required this.remoteRewardRequestsCount,
    required this.localStarLedgerCount,
    required this.remoteStarLedgerCount,
    required this.childBalanceDiagnostics,
    required this.hasRemoteChildBalanceData,
    required this.cloudConsistencyDiagnostic,
    required this.cloudConsistencyErrorText,
    required this.lastChildrenSyncAt,
    required this.lastMissionsSyncAt,
    required this.lastRewardsSyncAt,
    required this.lastMissionLogsSyncAt,
    required this.lastRewardRequestsSyncAt,
    required this.lastStarLedgerSyncAt,
    required this.lastFullSyncAt,
    required this.isSupabaseConfigured,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.onOpenAccount,
    required this.onSignOut,
    required this.onUpdateRemoteFamilyName,
    required this.onSyncCloudData,
    required this.onHistoricalRestore,
  });

  final AppSettings appSettings;
  final ZeniAccessibilitySettings accessibilitySettings;
  final ValueChanged<ZeniThemeModeOption> onThemeModeChanged;
  final ValueChanged<bool> onDyslexiaFontChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onTtsChanged;
  final ValueChanged<bool> onReadAloudByChildProfileChanged;
  final VoidCallback onConfigurePin;
  final ValueChanged<bool> onBiometricsChanged;
  final ZeniAuthState authState;
  final RemoteFamilySummary? remoteFamilySummary;
  final int localChildrenCount;
  final int? remoteChildrenCount;
  final int localMissionsCount;
  final int? remoteMissionsCount;
  final int localRewardsCount;
  final int? remoteRewardsCount;
  final int localMissionLogsCount;
  final int? remoteMissionLogsCount;
  final int localRewardRequestsCount;
  final int? remoteRewardRequestsCount;
  final int localStarLedgerCount;
  final int? remoteStarLedgerCount;
  final List<ChildBalanceDiagnostic> childBalanceDiagnostics;
  final bool hasRemoteChildBalanceData;
  final CloudConsistencyDiagnostic? cloudConsistencyDiagnostic;
  final String? cloudConsistencyErrorText;
  final DateTime? lastChildrenSyncAt;
  final DateTime? lastMissionsSyncAt;
  final DateTime? lastRewardsSyncAt;
  final DateTime? lastMissionLogsSyncAt;
  final DateTime? lastRewardRequestsSyncAt;
  final DateTime? lastStarLedgerSyncAt;
  final DateTime? lastFullSyncAt;
  final bool isSupabaseConfigured;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final VoidCallback onOpenAccount;
  final VoidCallback onSignOut;
  final Future<ZeniUpdateRemoteFamilyResult> Function({
    required String familyId,
    required String name,
  })
  onUpdateRemoteFamilyName;
  final Future<ZeniCloudSyncResult> Function() onSyncCloudData;
  final Future<HistoricalRestoreResult> Function() onHistoricalRestore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Preferências do app, acessibilidade e recursos da família.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          _ParentSettingsGroup(
            appSettings: appSettings,
            accessibilitySettings: accessibilitySettings,
            onThemeModeChanged: onThemeModeChanged,
            onDyslexiaFontChanged: onDyslexiaFontChanged,
            onTextScaleChanged: onTextScaleChanged,
            onVibrationChanged: onVibrationChanged,
            onNotificationsChanged: onNotificationsChanged,
            onTtsChanged: onTtsChanged,
            onReadAloudByChildProfileChanged: onReadAloudByChildProfileChanged,
            onConfigurePin: onConfigurePin,
            onBiometricsChanged: onBiometricsChanged,
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
            lastChildrenSyncAt: lastChildrenSyncAt,
            lastMissionsSyncAt: lastMissionsSyncAt,
            lastRewardsSyncAt: lastRewardsSyncAt,
            lastMissionLogsSyncAt: lastMissionLogsSyncAt,
            lastRewardRequestsSyncAt: lastRewardRequestsSyncAt,
            lastStarLedgerSyncAt: lastStarLedgerSyncAt,
            lastFullSyncAt: lastFullSyncAt,
            isSupabaseConfigured: isSupabaseConfigured,
            showHistoricalRestoreAction: showHistoricalRestoreAction,
            canRunHistoricalRestore: canRunHistoricalRestore,
            onOpenAccount: onOpenAccount,
            onSignOut: onSignOut,
            onUpdateRemoteFamilyName: onUpdateRemoteFamilyName,
            onSyncCloudData: onSyncCloudData,
            onHistoricalRestore: onHistoricalRestore,
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniOptionRow(
            title: 'Plano Premium',
            subtitle: 'Badge e recursos pagos serão definidos depois',
            leading: const Icon(
              Icons.workspace_premium_rounded,
              color: ZeniColors.warning,
            ),
            onTap: () {
              ZeniInfoPopup.show(
                context,
                title: 'Premium',
                message: 'Esse módulo será refinado na etapa de produto.',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ParentSettingsGroup extends StatelessWidget {
  const _ParentSettingsGroup({
    required this.appSettings,
    required this.accessibilitySettings,
    required this.onThemeModeChanged,
    required this.onDyslexiaFontChanged,
    required this.onTextScaleChanged,
    required this.onVibrationChanged,
    required this.onNotificationsChanged,
    required this.onTtsChanged,
    required this.onReadAloudByChildProfileChanged,
    required this.onConfigurePin,
    required this.onBiometricsChanged,
    required this.authState,
    required this.remoteFamilySummary,
    required this.localChildrenCount,
    required this.remoteChildrenCount,
    required this.localMissionsCount,
    required this.remoteMissionsCount,
    required this.localRewardsCount,
    required this.remoteRewardsCount,
    required this.localMissionLogsCount,
    required this.remoteMissionLogsCount,
    required this.localRewardRequestsCount,
    required this.remoteRewardRequestsCount,
    required this.localStarLedgerCount,
    required this.remoteStarLedgerCount,
    required this.childBalanceDiagnostics,
    required this.hasRemoteChildBalanceData,
    required this.cloudConsistencyDiagnostic,
    required this.cloudConsistencyErrorText,
    required this.lastChildrenSyncAt,
    required this.lastMissionsSyncAt,
    required this.lastRewardsSyncAt,
    required this.lastMissionLogsSyncAt,
    required this.lastRewardRequestsSyncAt,
    required this.lastStarLedgerSyncAt,
    required this.lastFullSyncAt,
    required this.isSupabaseConfigured,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.onOpenAccount,
    required this.onSignOut,
    required this.onUpdateRemoteFamilyName,
    required this.onSyncCloudData,
    required this.onHistoricalRestore,
  });

  final AppSettings appSettings;
  final ZeniAccessibilitySettings accessibilitySettings;
  final ValueChanged<ZeniThemeModeOption> onThemeModeChanged;
  final ValueChanged<bool> onDyslexiaFontChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onTtsChanged;
  final ValueChanged<bool> onReadAloudByChildProfileChanged;
  final VoidCallback onConfigurePin;
  final ValueChanged<bool> onBiometricsChanged;
  final ZeniAuthState authState;
  final RemoteFamilySummary? remoteFamilySummary;
  final int localChildrenCount;
  final int? remoteChildrenCount;
  final int localMissionsCount;
  final int? remoteMissionsCount;
  final int localRewardsCount;
  final int? remoteRewardsCount;
  final int localMissionLogsCount;
  final int? remoteMissionLogsCount;
  final int localRewardRequestsCount;
  final int? remoteRewardRequestsCount;
  final int localStarLedgerCount;
  final int? remoteStarLedgerCount;
  final List<ChildBalanceDiagnostic> childBalanceDiagnostics;
  final bool hasRemoteChildBalanceData;
  final CloudConsistencyDiagnostic? cloudConsistencyDiagnostic;
  final String? cloudConsistencyErrorText;
  final DateTime? lastChildrenSyncAt;
  final DateTime? lastMissionsSyncAt;
  final DateTime? lastRewardsSyncAt;
  final DateTime? lastMissionLogsSyncAt;
  final DateTime? lastRewardRequestsSyncAt;
  final DateTime? lastStarLedgerSyncAt;
  final DateTime? lastFullSyncAt;
  final bool isSupabaseConfigured;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final VoidCallback onOpenAccount;
  final VoidCallback onSignOut;
  final Future<ZeniUpdateRemoteFamilyResult> Function({
    required String familyId,
    required String name,
  })
  onUpdateRemoteFamilyName;
  final Future<ZeniCloudSyncResult> Function() onSyncCloudData;
  final Future<HistoricalRestoreResult> Function() onHistoricalRestore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZeniColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ZeniSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acessibilidade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            for (final option in ZeniThemeModeOption.values) ...[
              ZeniOptionRow(
                title: option.label,
                subtitle: option.description,
                selected: accessibilitySettings.themeModeOption == option,
                leading: Icon(switch (option) {
                  ZeniThemeModeOption.system => Icons.phone_iphone_rounded,
                  ZeniThemeModeOption.light => Icons.light_mode_rounded,
                  ZeniThemeModeOption.dark => Icons.dark_mode_rounded,
                }, color: ZeniColors.primaryDark),
                onTap: () => onThemeModeChanged(option),
              ),
              if (option != ZeniThemeModeOption.values.last)
                const SizedBox(height: ZeniSpacing.sm),
            ],
            const SizedBox(height: ZeniSpacing.md),
            ZeniSwitch(
              title: 'Fonte OpenDyslexic',
              subtitle: 'Aplicar a fonte acessível em todo o app',
              icon: Icons.text_fields_rounded,
              value: accessibilitySettings.dyslexiaFontEnabled,
              onChanged: onDyslexiaFontChanged,
            ),
            CounterStepper(
              label: 'Tamanho da letra',
              subtitle: 'Ajuste aplicado no app inteiro',
              value: (accessibilitySettings.textScale * 100).round(),
              min: 85,
              max: 135,
              step: 5,
              suffix: '%',
              onChanged: (value) => onTextScaleChanged(value / 100),
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniSwitch(
              title: 'Vibração',
              subtitle:
                  'Salvar preferência para feedback tátil do app nas próximas etapas',
              icon: Icons.vibration_rounded,
              value: accessibilitySettings.vibrationEnabled,
              onChanged: onVibrationChanged,
            ),
            ZeniSwitch(
              title: 'Notificações',
              subtitle:
                  'Salvar preferência para lembretes e pedidos de aprovação',
              icon: Icons.notifications_active_rounded,
              value: accessibilitySettings.notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
            ZeniSwitch(
              title: 'Leitura em voz alta',
              subtitle:
                  'Salvar preferência para TTS do dispositivo na próxima etapa',
              icon: Icons.record_voice_over_rounded,
              value: accessibilitySettings.ttsEnabled,
              onChanged: onTtsChanged,
            ),
            ZeniSwitch(
              title: 'Leitura por perfil da criança',
              subtitle:
                  'Permitir configuração individual de leitura em voz alta',
              icon: Icons.child_care_rounded,
              value: accessibilitySettings.readAloudByChildProfile,
              onChanged: onReadAloudByChildProfileChanged,
            ),
            const SizedBox(height: ZeniSpacing.sm),
            Text('Conta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: ZeniSpacing.md),
            if (!authState.isAuthenticated) ...[
              ZeniOptionRow(
                title: 'Criar conta para sincronizar',
                subtitle: isSupabaseConfigured
                    ? 'Conecte seu e-mail para proteger a família e preparar a sincronização futura'
                    : 'Disponível quando este build estiver configurado com Supabase Auth',
                leading: const Icon(
                  Icons.cloud_sync_rounded,
                  color: ZeniColors.primaryDark,
                ),
                onTap: onOpenAccount,
              ),
              const SizedBox(height: ZeniSpacing.sm),
            ] else ...[
              ZeniOptionRow(
                title: 'Conta conectada',
                subtitle: authState.user?.email ?? 'Conta autenticada',
                leading: const Icon(
                  Icons.verified_user_rounded,
                  color: ZeniColors.primaryDark,
                ),
              ),
              if (remoteFamilySummary != null) ...[
                const SizedBox(height: ZeniSpacing.sm),
                ZeniOptionRow(
                  title: 'Família remota preparada',
                  subtitle:
                      '${remoteFamilySummary!.familyName} · ${remoteFamilySummary!.roleLabel}',
                  leading: const Icon(
                    Icons.cloud_done_rounded,
                    color: ZeniColors.primaryDark,
                  ),
                  trailing: Text(
                    'Editar',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ZeniColors.primaryDark,
                    ),
                  ),
                  onTap: () =>
                      _openRemoteFamilyNameSheet(context, remoteFamilySummary!),
                ),
                const SizedBox(height: ZeniSpacing.sm),
                _CloudSyncSection(
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
                  lastChildrenSyncAt: lastChildrenSyncAt,
                  lastMissionsSyncAt: lastMissionsSyncAt,
                  lastRewardsSyncAt: lastRewardsSyncAt,
                  lastMissionLogsSyncAt: lastMissionLogsSyncAt,
                  lastRewardRequestsSyncAt: lastRewardRequestsSyncAt,
                  lastStarLedgerSyncAt: lastStarLedgerSyncAt,
                  onSyncCloudData: onSyncCloudData,
                  lastFullSyncAt: lastFullSyncAt,
                  showHistoricalRestoreAction: showHistoricalRestoreAction,
                  canRunHistoricalRestore: canRunHistoricalRestore,
                  onHistoricalRestore: onHistoricalRestore,
                ),
              ],
              const SizedBox(height: ZeniSpacing.sm),
              ZeniOptionRow(
                title: 'Sair da conta',
                subtitle:
                    'Os dados locais continuam neste aparelho mesmo sem sincronização',
                leading: const Icon(
                  Icons.logout_rounded,
                  color: ZeniColors.primaryDark,
                ),
                onTap: onSignOut,
              ),
              const SizedBox(height: ZeniSpacing.sm),
            ],
            Text('Segurança', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: ZeniSpacing.md),
            ZeniOptionRow(
              title: 'PIN do responsável',
              subtitle: appSettings.hasParentPin
                  ? 'Toque para alterar o PIN de 4 dígitos'
                  : 'Defina um PIN de 4 dígitos para proteger o acesso',
              leading: const Icon(
                Icons.pin_rounded,
                color: ZeniColors.primaryDark,
              ),
              trailing: Text(
                appSettings.hasParentPin ? 'Alterar' : 'Criar',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
              ),
              onTap: onConfigurePin,
            ),
            ZeniSwitch(
              title: 'Biometria',
              subtitle: appSettings.hasParentPin
                  ? 'Usar Face ID ou impressão digital antes do PIN'
                  : 'Configure um PIN para liberar a biometria',
              icon: Icons.fingerprint_rounded,
              value: appSettings.parentBiometricsEnabled,
              onChanged: appSettings.hasParentPin ? onBiometricsChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRemoteFamilyNameSheet(
    BuildContext context,
    RemoteFamilySummary summary,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _RemoteFamilyNameSheet(
          initialName: summary.familyName,
          onSubmit: (name) =>
              onUpdateRemoteFamilyName(familyId: summary.familyId, name: name),
        ),
      ),
    );
  }
}

class _CloudSyncSection extends StatefulWidget {
  const _CloudSyncSection({
    required this.localChildrenCount,
    required this.remoteChildrenCount,
    required this.localMissionsCount,
    required this.remoteMissionsCount,
    required this.localRewardsCount,
    required this.remoteRewardsCount,
    required this.localMissionLogsCount,
    required this.remoteMissionLogsCount,
    required this.localRewardRequestsCount,
    required this.remoteRewardRequestsCount,
    required this.localStarLedgerCount,
    required this.remoteStarLedgerCount,
    required this.childBalanceDiagnostics,
    required this.hasRemoteChildBalanceData,
    required this.cloudConsistencyDiagnostic,
    required this.cloudConsistencyErrorText,
    required this.lastChildrenSyncAt,
    required this.lastMissionsSyncAt,
    required this.lastRewardsSyncAt,
    required this.lastMissionLogsSyncAt,
    required this.lastRewardRequestsSyncAt,
    required this.lastStarLedgerSyncAt,
    required this.lastFullSyncAt,
    required this.onSyncCloudData,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.onHistoricalRestore,
  });

  final int localChildrenCount;
  final int? remoteChildrenCount;
  final int localMissionsCount;
  final int? remoteMissionsCount;
  final int localRewardsCount;
  final int? remoteRewardsCount;
  final int localMissionLogsCount;
  final int? remoteMissionLogsCount;
  final int localRewardRequestsCount;
  final int? remoteRewardRequestsCount;
  final int localStarLedgerCount;
  final int? remoteStarLedgerCount;
  final List<ChildBalanceDiagnostic> childBalanceDiagnostics;
  final bool hasRemoteChildBalanceData;
  final CloudConsistencyDiagnostic? cloudConsistencyDiagnostic;
  final String? cloudConsistencyErrorText;
  final DateTime? lastChildrenSyncAt;
  final DateTime? lastMissionsSyncAt;
  final DateTime? lastRewardsSyncAt;
  final DateTime? lastMissionLogsSyncAt;
  final DateTime? lastRewardRequestsSyncAt;
  final DateTime? lastStarLedgerSyncAt;
  final DateTime? lastFullSyncAt;
  final Future<ZeniCloudSyncResult> Function() onSyncCloudData;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final Future<HistoricalRestoreResult> Function() onHistoricalRestore;

  @override
  State<_CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends State<_CloudSyncSection> {
  bool _isSyncing = false;
  bool _isRestoring = false;
  String? _errorText;
  String? _restoreMessage;

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZeniOptionRow(
          title: 'Sincronização',
          subtitle: 'Dados preparados na nuvem · $summary',
          leading: const Icon(
            Icons.sync_rounded,
            color: ZeniColors.primaryDark,
          ),
          trailing: Text(
            _isSyncing ? 'Sincronizando...' : 'Sincronizar',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
          ),
          enabled: !_isSyncing,
          onTap: _isSyncing ? null : _syncAll,
        ),
        const SizedBox(height: ZeniSpacing.sm),
        Text(
          _syncStatusLabel(widget.lastFullSyncAt),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
        ),
        if (widget.lastChildrenSyncAt != null ||
            widget.lastMissionsSyncAt != null ||
            widget.lastRewardsSyncAt != null ||
            widget.lastMissionLogsSyncAt != null ||
            widget.lastRewardRequestsSyncAt != null ||
            widget.lastStarLedgerSyncAt != null) ...[
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            _buildDetailsLabel(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            _errorText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (widget.hasRemoteChildBalanceData) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Saldo remoto disponível para conferência',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
          if (widget.childBalanceDiagnostics.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              widget.childBalanceDiagnostics.any((item) => !item.isMatching)
                  ? widget
                                .cloudConsistencyDiagnostic
                                ?.hasOnlyExpectedPartialRestoreDivergence ??
                            false
                        ? 'Saldo ainda não restaurado neste aparelho. Use a nuvem apenas para conferência nesta etapa.'
                        : 'Diferença encontrada entre saldo local e saldo na nuvem.'
                  : 'Saldo local e saldo na nuvem conferem.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    widget.childBalanceDiagnostics.any(
                      (item) => !item.isMatching,
                    )
                    ? widget
                                  .cloudConsistencyDiagnostic
                                  ?.hasOnlyExpectedPartialRestoreDivergence ??
                              false
                          ? ZeniColors.primaryDark
                          : Theme.of(context).colorScheme.error
                    : ZeniColors.primaryDark,
              ),
            ),
            const SizedBox(height: ZeniSpacing.xs),
            for (final item in widget.childBalanceDiagnostics) ...[
              Text(
                widget
                            .cloudConsistencyDiagnostic
                            ?.hasOnlyExpectedPartialRestoreDivergence ??
                        false
                    ? '${item.childName}: Saldo na nuvem para conferência: ${item.remoteBalance} estrelas · Saldo local neste aparelho: ${item.localBalance} estrelas'
                    : '${item.childName}: Saldo local: ${item.localBalance} estrelas · Saldo na nuvem: ${item.remoteBalance} estrelas · Eventos no ledger: ${item.ledgerEventsCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
              if (item != widget.childBalanceDiagnostics.last)
                const SizedBox(height: ZeniSpacing.xs),
            ],
          ],
        ],
        if (widget.cloudConsistencyErrorText != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Não foi possível conferir a nuvem agora.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ] else if (widget.cloudConsistencyDiagnostic != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Conferência da nuvem',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            widget.cloudConsistencyDiagnostic!.isAligned
                ? 'Dados locais e nuvem parecem alinhados.'
                : widget
                      .cloudConsistencyDiagnostic!
                      .hasOnlyExpectedPartialRestoreDivergence
                ? 'Cadastros disponíveis neste aparelho'
                : 'Encontramos diferenças para conferir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  widget.cloudConsistencyDiagnostic!.isAligned ||
                      widget
                          .cloudConsistencyDiagnostic!
                          .hasOnlyExpectedPartialRestoreDivergence
                  ? ZeniColors.primaryDark
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          if (widget
              .cloudConsistencyDiagnostic!
              .hasOnlyExpectedPartialRestoreDivergence) ...[
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'Crianças, missões e mimos estão sincronizados.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'Saldo, histórico e sequência ainda não foram restaurados neste aparelho.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            'Crianças: ${widget.cloudConsistencyDiagnostic!.localChildrenCount}/${widget.cloudConsistencyDiagnostic!.remoteChildrenCount} · Missões: ${widget.cloudConsistencyDiagnostic!.localMissionsCount}/${widget.cloudConsistencyDiagnostic!.remoteMissionsCount} · Mimos: ${widget.cloudConsistencyDiagnostic!.localRewardsCount}/${widget.cloudConsistencyDiagnostic!.remoteRewardsCount}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            'Conclusões: ${widget.cloudConsistencyDiagnostic!.localMissionLogsCount}/${widget.cloudConsistencyDiagnostic!.remoteMissionLogsCount} · Pedidos: ${widget.cloudConsistencyDiagnostic!.localRewardRequestsCount}/${widget.cloudConsistencyDiagnostic!.remoteRewardRequestsCount}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            widget
                    .cloudConsistencyDiagnostic!
                    .hasOnlyExpectedPartialRestoreDivergence
                ? 'Saldo na nuvem para conferência: ${widget.cloudConsistencyDiagnostic!.remoteDerivedBalance} estrelas · Saldo local neste aparelho: ${widget.cloudConsistencyDiagnostic!.localStarBalance} estrelas'
                : 'Saldo local total: ${widget.cloudConsistencyDiagnostic!.localStarBalance} estrelas · Saldo remoto total: ${widget.cloudConsistencyDiagnostic!.remoteDerivedBalance} estrelas',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
        if (widget.showHistoricalRestoreAction) ...[
          const SizedBox(height: ZeniSpacing.md),
          ZeniOptionRow(
            title: 'Restaurar histórico e saldo',
            subtitle:
                'Traz conclusões, pedidos e eventos de estrelas da nuvem. A sequência não será restaurada nesta etapa.',
            leading: const Icon(
              Icons.history_rounded,
              color: ZeniColors.primaryDark,
            ),
            trailing: Text(
              _isRestoring ? 'Restaurando...' : 'Restaurar',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
            ),
            enabled: widget.canRunHistoricalRestore && !_isRestoring,
            onTap: widget.canRunHistoricalRestore && !_isRestoring
                ? _restoreHistory
                : null,
          ),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            widget.canRunHistoricalRestore
                ? 'Disponível apenas em aparelho recém-restaurado, sem atividade local posterior.'
                : 'Disponível quando este aparelho ainda não possui histórico local nem saldo reconstruído.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
          ),
          if (_restoreMessage != null) ...[
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              _restoreMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _restoreMessage!.startsWith('Histórico restaurado')
                    ? ZeniColors.primaryDark
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _buildSummary() {
    final childrenLabel = widget.remoteChildrenCount == null
        ? '${widget.localChildrenCount} crianças locais'
        : '${widget.remoteChildrenCount} criança${widget.remoteChildrenCount == 1 ? '' : 's'} preparada${widget.remoteChildrenCount == 1 ? '' : 's'}';
    final missionsLabel = widget.remoteMissionsCount == null
        ? '${widget.localMissionsCount} missões locais'
        : '${widget.remoteMissionsCount} miss${widget.remoteMissionsCount == 1 ? 'ão' : 'ões'} preparada${widget.remoteMissionsCount == 1 ? '' : 's'}';
    final rewardsLabel = widget.remoteRewardsCount == null
        ? '${widget.localRewardsCount} mimos locais'
        : '${widget.remoteRewardsCount} mimo${widget.remoteRewardsCount == 1 ? '' : 's'} preparado${widget.remoteRewardsCount == 1 ? '' : 's'}';
    final missionLogsLabel = widget.remoteMissionLogsCount == null
        ? '${widget.localMissionLogsCount} conclus${widget.localMissionLogsCount == 1 ? 'ão local' : 'ões locais'}'
        : '${widget.remoteMissionLogsCount} conclus${widget.remoteMissionLogsCount == 1 ? 'ão preparada' : 'ões preparadas'}';
    final rewardRequestsLabel = widget.remoteRewardRequestsCount == null
        ? '${widget.localRewardRequestsCount} pedido${widget.localRewardRequestsCount == 1 ? ' local' : 's locais'}'
        : '${widget.remoteRewardRequestsCount} pedido${widget.remoteRewardRequestsCount == 1 ? ' preparado' : 's preparados'}';
    final starLedgerLabel = widget.remoteStarLedgerCount == null
        ? '${widget.localStarLedgerCount} evento${widget.localStarLedgerCount == 1 ? ' local' : 's locais'}'
        : '${widget.remoteStarLedgerCount} evento${widget.remoteStarLedgerCount == 1 ? ' preparado' : 's preparados'}';
    return '$childrenLabel · $missionsLabel · $rewardsLabel · $missionLogsLabel · $rewardRequestsLabel · $starLedgerLabel';
  }

  String _buildDetailsLabel() {
    final children = widget.lastChildrenSyncAt == null
        ? 'Crianças ainda não sincronizadas'
        : 'Crianças preparadas';
    final missions = widget.lastMissionsSyncAt == null
        ? 'Missões pendentes'
        : 'Missões preparadas';
    final rewards = widget.lastRewardsSyncAt == null
        ? 'Mimos pendentes'
        : 'Mimos preparados';
    final missionLogs = widget.lastMissionLogsSyncAt == null
        ? 'Conclusões pendentes'
        : 'Conclusões preparadas';
    final rewardRequests = widget.lastRewardRequestsSyncAt == null
        ? 'Pedidos pendentes'
        : 'Pedidos preparados';
    final starLedger = widget.lastStarLedgerSyncAt == null
        ? 'Eventos pendentes'
        : 'Eventos preparados';
    return '$children · $missions · $rewards · $missionLogs · $rewardRequests · $starLedger';
  }

  Future<void> _syncAll() async {
    setState(() {
      _isSyncing = true;
      _errorText = null;
    });

    final result = await widget.onSyncCloudData();
    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _errorText = result.isSuccess ? null : result.message;
    });
  }

  Future<void> _restoreHistory() async {
    setState(() {
      _isRestoring = true;
      _restoreMessage = null;
    });

    final result = await widget.onHistoricalRestore();
    if (!mounted) return;

    setState(() {
      _isRestoring = false;
      _restoreMessage = result.message;
    });
  }
}

String _syncStatusLabel(DateTime? value) {
  if (value == null) {
    return 'Ainda não sincronizado';
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return 'Última sincronização: $day/$month/$year às $hour:$minute';
}

class _RemoteFamilyNameSheet extends StatefulWidget {
  const _RemoteFamilyNameSheet({
    required this.initialName,
    required this.onSubmit,
  });

  final String initialName;
  final Future<ZeniUpdateRemoteFamilyResult> Function(String name) onSubmit;

  @override
  State<_RemoteFamilyNameSheet> createState() => _RemoteFamilyNameSheetState();
}

class _RemoteFamilyNameSheetState extends State<_RemoteFamilyNameSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Nome da família remota',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniTextInput(
              key: const Key('remote-family-name-input'),
              controller: _nameController,
              label: 'Nome da família',
              hint: 'Ex.: Família da Luna',
              textInputAction: TextInputAction.done,
              errorText: _errorText,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: _isSaving ? 'Salvando...' : 'Salvar nome',
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniSecondaryButton(
              label: 'Cancelar',
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _errorText = 'Digite um nome para a família.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final result = await widget.onSubmit(trimmedName);
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = false;
      _errorText =
          result.message ??
          'Não foi possível atualizar a família remota agora.';
    });
  }
}

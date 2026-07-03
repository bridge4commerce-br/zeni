import 'package:flutter/material.dart';

import '../../../../core/accessibility/zeni_accessibility_settings.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/counter_stepper.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../auth/data/repositories/zeni_account_repository.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../sync/data/models/device_bootstrap_result.dart';
import '../../../sync/data/models/cloud_consistency_diagnostic.dart';
import '../../../sync/data/models/historical_restore_result.dart';
import '../../../sync/presentation/providers/cloud_sync_providers.dart';

class ParentSettingsTab extends StatelessWidget {
  const ParentSettingsTab({
    super.key,
    required this.parentDisplayName,
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
    required this.supabaseBootstrapState,
    required this.isGoogleSignInAvailable,
    required this.isAppleSignInAvailable,
    required this.showHistoricalRestoreStatus,
    required this.showDeviceBootstrapStatus,
    required this.showDeviceBootstrapAction,
    required this.canRunDeviceBootstrap,
    required this.deviceBootstrapMessage,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.historicalRestoreMessage,
    required this.onOpenAccount,
    required this.onSignOut,
    required this.onManageAccountAndData,
    required this.onClearLocalDeviceData,
    required this.onUpdateParentDisplayName,
    required this.onUpdateRemoteFamilyName,
    required this.onSyncCloudData,
    required this.onDeviceBootstrap,
    required this.onHistoricalRestore,
  });

  final String parentDisplayName;
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
  final ZeniSupabaseBootstrapState supabaseBootstrapState;
  final bool isGoogleSignInAvailable;
  final bool isAppleSignInAvailable;
  final bool showHistoricalRestoreStatus;
  final bool showDeviceBootstrapStatus;
  final bool showDeviceBootstrapAction;
  final bool canRunDeviceBootstrap;
  final String? deviceBootstrapMessage;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final String? historicalRestoreMessage;
  final VoidCallback onOpenAccount;
  final VoidCallback onSignOut;
  final VoidCallback onManageAccountAndData;
  final Future<void> Function() onClearLocalDeviceData;
  final Future<void> Function(String name) onUpdateParentDisplayName;
  final Future<ZeniUpdateRemoteFamilyResult> Function({
    required String familyId,
    required String name,
  })
  onUpdateRemoteFamilyName;
  final Future<ZeniCloudSyncResult> Function() onSyncCloudData;
  final Future<DeviceBootstrapResult> Function() onDeviceBootstrap;
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
            parentDisplayName: parentDisplayName,
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
            onOpenAccount: onOpenAccount,
            onSignOut: onSignOut,
            onManageAccountAndData: onManageAccountAndData,
            onClearLocalDeviceData: onClearLocalDeviceData,
            onUpdateParentDisplayName: onUpdateParentDisplayName,
            onUpdateRemoteFamilyName: onUpdateRemoteFamilyName,
            onSyncCloudData: onSyncCloudData,
            onDeviceBootstrap: onDeviceBootstrap,
            onHistoricalRestore: onHistoricalRestore,
          ),
        ],
      ),
    );
  }
}

class _ParentSettingsGroup extends StatelessWidget {
  const _ParentSettingsGroup({
    required this.parentDisplayName,
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
    required this.supabaseBootstrapState,
    required this.isGoogleSignInAvailable,
    required this.isAppleSignInAvailable,
    required this.showHistoricalRestoreStatus,
    required this.showDeviceBootstrapStatus,
    required this.showDeviceBootstrapAction,
    required this.canRunDeviceBootstrap,
    required this.deviceBootstrapMessage,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.historicalRestoreMessage,
    required this.onOpenAccount,
    required this.onSignOut,
    required this.onManageAccountAndData,
    required this.onClearLocalDeviceData,
    required this.onUpdateParentDisplayName,
    required this.onUpdateRemoteFamilyName,
    required this.onSyncCloudData,
    required this.onDeviceBootstrap,
    required this.onHistoricalRestore,
  });

  final String parentDisplayName;
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
  final ZeniSupabaseBootstrapState supabaseBootstrapState;
  final bool isGoogleSignInAvailable;
  final bool isAppleSignInAvailable;
  final bool showHistoricalRestoreStatus;
  final bool showDeviceBootstrapStatus;
  final bool showDeviceBootstrapAction;
  final bool canRunDeviceBootstrap;
  final String? deviceBootstrapMessage;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final String? historicalRestoreMessage;
  final VoidCallback onOpenAccount;
  final VoidCallback onSignOut;
  final VoidCallback onManageAccountAndData;
  final Future<void> Function() onClearLocalDeviceData;
  final Future<void> Function(String name) onUpdateParentDisplayName;
  final Future<ZeniUpdateRemoteFamilyResult> Function({
    required String familyId,
    required String name,
  })
  onUpdateRemoteFamilyName;
  final Future<ZeniCloudSyncResult> Function() onSyncCloudData;
  final Future<DeviceBootstrapResult> Function() onDeviceBootstrap;
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
            _ParentProfileCard(
              name: parentDisplayName,
              email: authState.user?.email,
              onTap: () => _openParentProfileNameSheet(context),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            _SectionTitle(title: 'Segurança'),
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
            const SizedBox(height: ZeniSpacing.xl),
            _SectionTitle(title: 'Preferências'),
            Text(
              'Tema e acessibilidade',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ZeniSpacing.sm),
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
              subtitle: 'Ativar feedback tátil do app',
              icon: Icons.vibration_rounded,
              value: accessibilitySettings.vibrationEnabled,
              onChanged: onVibrationChanged,
            ),
            ZeniSwitch(
              title: 'Notificações',
              subtitle: 'Receber lembretes e pedidos de aprovação',
              icon: Icons.notifications_active_rounded,
              value: accessibilitySettings.notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
            ZeniSwitch(
              title: 'Leitura em voz alta',
              subtitle: 'Usar a voz do dispositivo quando disponível',
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
            const SizedBox(height: ZeniSpacing.xl),
            _SectionTitle(title: 'Sincronização e backup'),
            if (authState.isAuthenticated && remoteFamilySummary != null) ...[
              ZeniOptionRow(
                title: 'Nome da família no backup',
                subtitle: remoteFamilySummary!.familyName,
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
              ),
            ] else if (authState.isAuthenticated &&
                remoteFamilySummary == null) ...[
              Text(
                'Sua conta está conectada, mas ainda não encontramos um backup da família para este aparelho.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.sm),
              _CloudConnectionCard(
                title: 'Configurar sincronização',
                subtitle: 'Abra sua conta para preparar backup e restauração.',
                onTap: onOpenAccount,
              ),
            ] else ...[
              Text(
                'Conecte sua conta para salvar um backup da família e restaurar em outro aparelho quando precisar.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.sm),
              _CloudConnectionCard(
                title: 'Conectar conta',
                subtitle: !supabaseBootstrapState.isConfigured
                    ? 'A nuvem não foi incluída neste build.'
                    : supabaseBootstrapState.isInitialized
                    ? 'Ative backup, sincronização e restauração.'
                    : 'A conexão com a nuvem falhou ao iniciar neste aparelho.',
                onTap: onOpenAccount,
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            _BackupRestoreSection(
              isAvailable:
                  authState.isAuthenticated && remoteFamilySummary != null,
              showDeviceBootstrapStatus: showDeviceBootstrapStatus,
              showHistoricalRestoreStatus: showHistoricalRestoreStatus,
              showDeviceBootstrapAction: showDeviceBootstrapAction,
              canRunDeviceBootstrap: canRunDeviceBootstrap,
              deviceBootstrapMessage: deviceBootstrapMessage,
              showHistoricalRestoreAction: showHistoricalRestoreAction,
              canRunHistoricalRestore: canRunHistoricalRestore,
              historicalRestoreMessage: historicalRestoreMessage,
              onDeviceBootstrap: onDeviceBootstrap,
              onHistoricalRestore: onHistoricalRestore,
            ),
            const SizedBox(height: ZeniSpacing.xl),
            _SectionTitle(title: 'Ajuda e informações'),
            ZeniOptionRow(
              title: 'Suporte',
              subtitle:
                  'Ajuda com conta, sincronização, restauração e privacidade.',
              leading: const Icon(
                Icons.support_agent_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () => _openInfoSheet(
                context,
                title: 'Suporte',
                message:
                    'Para ajuda com conta, sincronização, restauração, exclusão de conta ou dúvidas sobre privacidade, entre em contato com o suporte.\n\nE-mail: suporte@luminadigital.app',
              ),
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Política de Privacidade',
              subtitle: 'Como o app salva e pode sincronizar dados da família.',
              leading: const Icon(
                Icons.privacy_tip_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () => _openInfoSheet(
                context,
                title: 'Política de Privacidade',
                message:
                    'O Zeni salva dados da família para organizar crianças, missões, mimos, pedidos e histórico de estrelas. O app pode funcionar apenas neste aparelho. Quando você entra com uma conta, parte desses dados pode ser sincronizada na nuvem para permitir restauração e continuidade em outro aparelho. Você pode apagar dados locais deste aparelho e também solicitar a exclusão da conta e dos dados da nuvem.',
              ),
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Termos de Uso',
              subtitle:
                  'Resumo das responsabilidades e do uso adequado do app.',
              leading: const Icon(
                Icons.description_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () => _openInfoSheet(
                context,
                title: 'Termos de Uso',
                message:
                    'O Zeni é uma ferramenta de organização familiar. O responsável é quem cria e gerencia crianças, missões, mimos e aprovações. O app não substitui acompanhamento parental, financeiro, educacional ou profissional. Ao usar recursos de conta e nuvem, você concorda em manter suas credenciais seguras e usar o app de forma adequada à sua família.',
              ),
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Como seus dados são salvos',
              subtitle:
                  'Entenda o que fica neste aparelho e o que pode ir para a sua conta.',
              leading: const Icon(
                Icons.cloud_queue_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () => _openInfoSheet(
                context,
                title: 'Como seus dados são salvos',
                message:
                    'O Zeni foi pensado para funcionar de forma local/offline. Os dados salvos neste aparelho continuam disponíveis mesmo sem login. Entrar com uma conta é opcional e permite sincronizar ou restaurar dados da família pela nuvem. Sair da conta remove apenas a sessão. Apagar dados deste aparelho não apaga a nuvem. A exclusão completa da conta e dos dados da nuvem ficará para uma etapa própria.',
              ),
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Informações técnicas para suporte',
              subtitle:
                  'Abra apenas se precisar compartilhar diagnóstico com o suporte.',
              leading: const Icon(
                Icons.health_and_safety_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () => _openTechnicalDiagnosticsSheet(context),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            _SectionTitle(title: 'Conta e dados'),
            if (authState.isAuthenticated) ...[
              ZeniOptionRow(
                title: 'Sair da conta',
                subtitle:
                    'Sair da conta remove apenas sua sessão neste aparelho. A família e os dados locais continuam salvos aqui.',
                leading: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: onSignOut,
              ),
              const SizedBox(height: ZeniSpacing.sm),
            ],
            ZeniOptionRow(
              title: 'Apagar dados deste aparelho',
              subtitle:
                  'Remove os dados locais deste aparelho sem apagar o que estiver salvo na sua conta.',
              leading: Icon(
                Icons.delete_forever_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () async {
                await onClearLocalDeviceData();
              },
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Excluir conta e dados da nuvem',
              subtitle:
                  'Indisponível nesta versão. Veja o que muda entre dados locais, conta e nuvem.',
              leading: Icon(
                Icons.cloud_off_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: onManageAccountAndData,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsInfoSheet(title: title, message: message),
    );
  }

  Future<void> _openTechnicalDiagnosticsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TechnicalDiagnosticsSheet(
        bootstrapState: supabaseBootstrapState,
        isGoogleSignInAvailable: isGoogleSignInAvailable,
        isAppleSignInAvailable: isAppleSignInAvailable,
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

  Future<void> _openParentProfileNameSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ParentProfileNameSheet(
          initialName: parentDisplayName,
          onSubmit: onUpdateParentDisplayName,
        ),
      ),
    );
  }
}

class _SettingsInfoSheet extends StatelessWidget {
  const _SettingsInfoSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: title,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalDiagnosticsSheet extends StatelessWidget {
  const _TechnicalDiagnosticsSheet({
    required this.bootstrapState,
    required this.isGoogleSignInAvailable,
    required this.isAppleSignInAvailable,
  });

  final ZeniSupabaseBootstrapState bootstrapState;
  final bool isGoogleSignInAvailable;
  final bool isAppleSignInAvailable;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Diagnóstico técnico',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo seguro para suporte interno. Este painel não mostra URL completa, anon key nem client IDs.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            _DiagnosticRow(
              label: 'Supabase configurado',
              value: bootstrapState.isConfigured ? 'Sim' : 'Não',
            ),
            _DiagnosticRow(
              label: 'Supabase inicializado',
              value: bootstrapState.isInitialized ? 'Sim' : 'Não',
            ),
            _DiagnosticRow(
              label: 'Mensagem do bootstrap',
              value: zeniRedactTechnicalMessage(bootstrapState.message),
            ),
            _DiagnosticRow(
              label: 'Google disponível',
              value: isGoogleSignInAvailable ? 'Sim' : 'Não',
            ),
            _DiagnosticRow(
              label: 'Apple disponível',
              value: isAppleSignInAvailable ? 'Sim' : 'Não',
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeniSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeniSpacing.md),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _ParentProfileCard extends StatelessWidget {
  const _ParentProfileCard({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String? email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedName = name.trim().isEmpty ? 'Responsável' : name.trim();
    final emailLabel = email?.trim().isNotEmpty == true
        ? email!.trim()
        : 'Conta não conectada';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(ZeniSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ZeniColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: ZeniColors.primary.withValues(alpha: 0.12),
              foregroundColor: ZeniColors.primaryDark,
              child: Text(
                resolvedName.characters.first.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: ZeniSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: ZeniSpacing.xs),
                  Text(
                    emailLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ZeniSpacing.sm),
            Text(
              'Editar',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudConnectionCard extends StatelessWidget {
  const _CloudConnectionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ZeniOptionRow(
      title: title,
      subtitle: subtitle,
      leading: const Icon(
        Icons.cloud_sync_rounded,
        color: ZeniColors.primaryDark,
      ),
      trailing: Text(
        'Abrir',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
      ),
      onTap: onTap,
    );
  }
}

class _BackupRestoreSection extends StatefulWidget {
  const _BackupRestoreSection({
    required this.isAvailable,
    required this.showDeviceBootstrapStatus,
    required this.showHistoricalRestoreStatus,
    required this.showDeviceBootstrapAction,
    required this.canRunDeviceBootstrap,
    required this.deviceBootstrapMessage,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.historicalRestoreMessage,
    required this.onDeviceBootstrap,
    required this.onHistoricalRestore,
  });

  final bool isAvailable;
  final bool showDeviceBootstrapStatus;
  final bool showHistoricalRestoreStatus;
  final bool showDeviceBootstrapAction;
  final bool canRunDeviceBootstrap;
  final String? deviceBootstrapMessage;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final String? historicalRestoreMessage;
  final Future<DeviceBootstrapResult> Function() onDeviceBootstrap;
  final Future<HistoricalRestoreResult> Function() onHistoricalRestore;

  @override
  State<_BackupRestoreSection> createState() => _BackupRestoreSectionState();
}

class _BackupRestoreSectionState extends State<_BackupRestoreSection> {
  bool _isBootstrapping = false;
  bool _isRestoring = false;
  String? _bootstrapMessage;
  String? _restoreMessage;

  bool get _canOpenSheet =>
      widget.isAvailable &&
      (widget.showDeviceBootstrapStatus || widget.showHistoricalRestoreStatus);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZeniOptionRow(
          title: 'Restaurar backup',
          subtitle: 'Traga os dados salvos na sua conta para este aparelho.',
          leading: const Icon(
            Icons.cloud_download_rounded,
            color: ZeniColors.primaryDark,
          ),
          trailing: Text(
            'Restaurar',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: ZeniColors.primaryDark),
          ),
          enabled: _canOpenSheet,
          onTap: _canOpenSheet ? _openRestoreOptionsSheet : null,
        ),
        if (_bootstrapMessage != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            _bootstrapMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  _bootstrapMessage!.startsWith(
                    'Dados principais restaurados neste aparelho.',
                  )
                  ? ZeniColors.primaryDark
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (_restoreMessage != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            _restoreMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  _restoreMessage!.startsWith(
                    'Histórico e saldo restaurados com segurança',
                  )
                  ? ZeniColors.primaryDark
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openRestoreOptionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloudRestoreOptionsSheet(
        isBootstrapping: _isBootstrapping,
        isRestoring: _isRestoring,
        showDeviceBootstrapAction: widget.showDeviceBootstrapAction,
        canRunDeviceBootstrap: widget.canRunDeviceBootstrap,
        deviceBootstrapMessage: widget.deviceBootstrapMessage,
        showHistoricalRestoreAction: widget.showHistoricalRestoreAction,
        canRunHistoricalRestore: widget.canRunHistoricalRestore,
        historicalRestoreMessage: widget.historicalRestoreMessage,
        onRestoreDeviceBootstrap:
            widget.canRunDeviceBootstrap && !_isBootstrapping
            ? _restoreDeviceBootstrap
            : null,
        onRestoreHistory: widget.canRunHistoricalRestore && !_isRestoring
            ? _restoreHistory
            : null,
      ),
    );
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

  Future<void> _restoreDeviceBootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _bootstrapMessage = null;
    });

    final result = await widget.onDeviceBootstrap();
    if (!mounted) return;

    setState(() {
      _isBootstrapping = false;
      _bootstrapMessage = result.message;
    });
  }
}

class _ParentProfileNameSheet extends StatefulWidget {
  const _ParentProfileNameSheet({
    required this.initialName,
    required this.onSubmit,
  });

  final String initialName;
  final Future<void> Function(String name) onSubmit;

  @override
  State<_ParentProfileNameSheet> createState() =>
      _ParentProfileNameSheetState();
}

class _ParentProfileNameSheetState extends State<_ParentProfileNameSheet> {
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
      title: 'Perfil do responsável',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZeniTextInput(
            controller: _nameController,
            label: 'Nome do responsável',
            hint: 'Responsável',
            key: const Key('parent-display-name-input'),
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
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _errorText = 'Digite um nome para o responsável.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    await widget.onSubmit(trimmedName);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop();
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

  @override
  State<_CloudSyncSection> createState() => _CloudSyncSectionState();
}

class _CloudSyncSectionState extends State<_CloudSyncSection> {
  bool _isSyncing = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final simpleSummary = _buildSimpleSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZeniOptionRow(
          title: 'Sincronização e backup',
          subtitle: simpleSummary,
          leading: const Icon(
            Icons.sync_rounded,
            color: ZeniColors.primaryDark,
          ),
          trailing: Text(
            _isSyncing ? 'Sincronizando...' : 'Sincronizar agora',
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
        if (_errorText != null) ...[
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            _errorText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: ZeniSpacing.sm),
        ZeniOptionRow(
          title: 'Ver detalhes',
          subtitle:
              'Conferência, histórico de sincronização e informações da nuvem.',
          leading: const Icon(
            Icons.info_outline_rounded,
            color: ZeniColors.primaryDark,
          ),
          onTap: _openDetailsSheet,
        ),
      ],
    );
  }

  String _buildSimpleSummary() {
    if (_hasPendingSync()) {
      return 'Há dados aguardando sincronização';
    }

    return 'Tudo salvo na sua conta';
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

  Future<void> _openDetailsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloudSyncDetailsSheet(
        summary: _buildSummary(),
        detailsLabel: _buildDetailsLabel(),
        childBalanceDiagnostics: widget.childBalanceDiagnostics,
        hasRemoteChildBalanceData: widget.hasRemoteChildBalanceData,
        cloudConsistencyDiagnostic: widget.cloudConsistencyDiagnostic,
        cloudConsistencyErrorText: widget.cloudConsistencyErrorText,
      ),
    );
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

  bool _hasPendingSync() {
    if (_errorText != null || widget.cloudConsistencyErrorText != null) {
      return true;
    }
    if (widget.lastFullSyncAt == null) {
      return true;
    }
    if (widget.cloudConsistencyDiagnostic == null) {
      return false;
    }

    return !widget.cloudConsistencyDiagnostic!.isAligned &&
        !widget
            .cloudConsistencyDiagnostic!
            .hasOnlyExpectedPartialRestoreDivergence;
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

class _CloudSyncDetailsSheet extends StatelessWidget {
  const _CloudSyncDetailsSheet({
    required this.summary,
    required this.detailsLabel,
    required this.childBalanceDiagnostics,
    required this.hasRemoteChildBalanceData,
    required this.cloudConsistencyDiagnostic,
    required this.cloudConsistencyErrorText,
  });

  final String summary;
  final String detailsLabel;
  final List<ChildBalanceDiagnostic> childBalanceDiagnostics;
  final bool hasRemoteChildBalanceData;
  final CloudConsistencyDiagnostic? cloudConsistencyDiagnostic;
  final String? cloudConsistencyErrorText;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Detalhes da sincronização',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              detailsLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
            ),
            if (hasRemoteChildBalanceData) ...[
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Saldo remoto disponível para conferência',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeniSpacing.xs),
              if (childBalanceDiagnostics.isNotEmpty)
                Text(
                  childBalanceDiagnostics.any((item) => !item.isMatching)
                      ? cloudConsistencyDiagnostic
                                    ?.hasOnlyExpectedPartialRestoreDivergence ??
                                false
                            ? 'Saldo ainda não restaurado neste aparelho. Use a nuvem apenas para conferência nesta etapa.'
                            : 'Diferença encontrada entre saldo local e saldo na nuvem.'
                      : 'Saldo local e saldo na nuvem conferem.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        childBalanceDiagnostics.any((item) => !item.isMatching)
                        ? cloudConsistencyDiagnostic
                                      ?.hasOnlyExpectedPartialRestoreDivergence ??
                                  false
                              ? ZeniColors.primaryDark
                              : Theme.of(context).colorScheme.error
                        : ZeniColors.primaryDark,
                  ),
                ),
              if (childBalanceDiagnostics.isNotEmpty) ...[
                const SizedBox(height: ZeniSpacing.xs),
                for (final item in childBalanceDiagnostics) ...[
                  Text(
                    cloudConsistencyDiagnostic
                                ?.hasOnlyExpectedPartialRestoreDivergence ??
                            false
                        ? '${item.childName}: Saldo na nuvem para conferência: ${item.remoteBalance} estrelas · Saldo local neste aparelho: ${item.localBalance} estrelas'
                        : '${item.childName}: Saldo local: ${item.localBalance} estrelas · Saldo na nuvem: ${item.remoteBalance} estrelas · Eventos no ledger: ${item.ledgerEventsCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                  if (item != childBalanceDiagnostics.last)
                    const SizedBox(height: ZeniSpacing.xs),
                ],
              ],
            ],
            if (cloudConsistencyErrorText != null) ...[
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Não foi possível conferir a nuvem agora.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ] else if (cloudConsistencyDiagnostic != null) ...[
              const SizedBox(height: ZeniSpacing.lg),
              Text(
                'Conferência da nuvem',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                cloudConsistencyDiagnostic!.isAligned
                    ? 'Dados locais e nuvem parecem alinhados.'
                    : cloudConsistencyDiagnostic!
                          .hasOnlyExpectedPartialRestoreDivergence
                    ? 'Cadastros disponíveis neste aparelho'
                    : 'Encontramos diferenças para conferir.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      cloudConsistencyDiagnostic!.isAligned ||
                          cloudConsistencyDiagnostic!
                              .hasOnlyExpectedPartialRestoreDivergence
                      ? ZeniColors.primaryDark
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              if (cloudConsistencyDiagnostic!
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
                'Crianças: ${cloudConsistencyDiagnostic!.localChildrenCount}/${cloudConsistencyDiagnostic!.remoteChildrenCount} · Missões: ${cloudConsistencyDiagnostic!.localMissionsCount}/${cloudConsistencyDiagnostic!.remoteMissionsCount} · Mimos: ${cloudConsistencyDiagnostic!.localRewardsCount}/${cloudConsistencyDiagnostic!.remoteRewardsCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                'Conclusões: ${cloudConsistencyDiagnostic!.localMissionLogsCount}/${cloudConsistencyDiagnostic!.remoteMissionLogsCount} · Pedidos: ${cloudConsistencyDiagnostic!.localRewardRequestsCount}/${cloudConsistencyDiagnostic!.remoteRewardRequestsCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                cloudConsistencyDiagnostic!
                        .hasOnlyExpectedPartialRestoreDivergence
                    ? 'Saldo na nuvem para conferência: ${cloudConsistencyDiagnostic!.remoteDerivedBalance} estrelas · Saldo local neste aparelho: ${cloudConsistencyDiagnostic!.localStarBalance} estrelas'
                    : 'Saldo local total: ${cloudConsistencyDiagnostic!.localStarBalance} estrelas · Saldo remoto total: ${cloudConsistencyDiagnostic!.remoteDerivedBalance} estrelas',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
            ],
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudRestoreOptionsSheet extends StatelessWidget {
  const _CloudRestoreOptionsSheet({
    required this.isBootstrapping,
    required this.isRestoring,
    required this.showDeviceBootstrapAction,
    required this.canRunDeviceBootstrap,
    required this.deviceBootstrapMessage,
    required this.showHistoricalRestoreAction,
    required this.canRunHistoricalRestore,
    required this.historicalRestoreMessage,
    required this.onRestoreDeviceBootstrap,
    required this.onRestoreHistory,
  });

  final bool isBootstrapping;
  final bool isRestoring;
  final bool showDeviceBootstrapAction;
  final bool canRunDeviceBootstrap;
  final String? deviceBootstrapMessage;
  final bool showHistoricalRestoreAction;
  final bool canRunHistoricalRestore;
  final String? historicalRestoreMessage;
  final VoidCallback? onRestoreDeviceBootstrap;
  final VoidCallback? onRestoreHistory;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Restaurar backup',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha como trazer os dados salvos na sua conta para este aparelho.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            if (showDeviceBootstrapAction) ...[
              const SizedBox(height: ZeniSpacing.lg),
              ZeniOptionRow(
                title: 'Restaurar minha família',
                subtitle:
                    'Traz família, crianças, missões e mimos para este aparelho.',
                leading: const Icon(
                  Icons.cloud_download_rounded,
                  color: ZeniColors.primaryDark,
                ),
                trailing: Text(
                  isBootstrapping ? 'Restaurando...' : 'Restaurar',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ZeniColors.primaryDark,
                  ),
                ),
                enabled: canRunDeviceBootstrap && !isBootstrapping,
                onTap: onRestoreDeviceBootstrap,
              ),
              if (deviceBootstrapMessage != null) ...[
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  deviceBootstrapMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ],
            if (showHistoricalRestoreAction) ...[
              const SizedBox(height: ZeniSpacing.md),
              ZeniOptionRow(
                title: 'Restaurar histórico e saldo',
                subtitle:
                    'Reconstrói histórico e saldo com segurança a partir da nuvem.',
                leading: const Icon(
                  Icons.history_rounded,
                  color: ZeniColors.primaryDark,
                ),
                trailing: Text(
                  isRestoring ? 'Restaurando...' : 'Restaurar',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ZeniColors.primaryDark,
                  ),
                ),
                enabled: canRunHistoricalRestore && !isRestoring,
                onTap: onRestoreHistory,
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                'A sequência não será restaurada nesta fase.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
              ),
              if (historicalRestoreMessage != null) ...[
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  historicalRestoreMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ],
            const SizedBox(height: ZeniSpacing.lg),
            ZeniPrimaryButton(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
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

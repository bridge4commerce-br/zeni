import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/zeni_accessibility_controller.dart';
import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/providers/zeni_repository_providers.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_fab.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/layout/zeni_bottom_nav_bar.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../auth/local/parent_biometric_auth.dart';
import '../../../auth/presentation/providers/zeni_account_providers.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../auth/presentation/widgets/auth_account_sheet.dart';
import '../../../balance/domain/monthly_star_projection.dart';
import '../../../balance/presentation/providers/remote_child_balance_providers.dart';
import '../../../balance/presentation/providers/remote_star_ledger_providers.dart';
import '../../../auth/presentation/widgets/parent_pin_dialog.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/models/family.dart';
import '../../../family/data/models/family_member.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/widgets/reward_detail_form.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../sync/data/models/historical_restore_result.dart';
import '../../../sync/presentation/providers/cloud_consistency_providers.dart';
import '../../../sync/presentation/providers/cloud_sync_providers.dart';
import '../../../sync/presentation/providers/historical_restore_providers.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../widgets/monthly_star_projection_card.dart';
import '../widgets/parent_child_form_sheet.dart';
import '../widgets/parent_child_summary_card.dart';
import '../widgets/parent_family_tab.dart';
import '../widgets/parent_metric_card.dart';
import '../widgets/parent_missions_tab.dart';
import '../widgets/parent_rewards_tab.dart';
import '../widgets/parent_settings_tab.dart';

class ParentShellPage extends ConsumerStatefulWidget {
  const ParentShellPage({super.key});

  @override
  ConsumerState<ParentShellPage> createState() => _ParentShellPageState();
}

class _ParentShellPageState extends ConsumerState<ParentShellPage> {
  int _currentIndex = 0;

  ZeniAppState? get _currentAppState =>
      ref.read(zeniAppStateControllerProvider).asData?.value;

  _ParentModeData _buildParentModeData(ZeniAppState appState) {
    final ledgerEntries = [...appState.starLedgerEntries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final awaitingLogs = appState.missionLogs
        .where((log) => log.status == MissionLogStatus.awaitingApproval)
        .toList();
    final pendingRequests = appState.rewardRequests
        .where((request) => request.status == RewardRequestStatus.pending)
        .toList();

    return _ParentModeData(
      family: appState.family,
      children: appState.children,
      members: appState.familyMembers,
      missions: appState.missions,
      awaitingLogs: awaitingLogs,
      rewards: appState.rewards,
      pendingRequests: pendingRequests,
      ledgerEntries: ledgerEntries,
    );
  }

  Future<void> _openCreateMissionSheet() async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final result = await showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: TaskFormSheet(children: data.children),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final mission = await ref
        .read(missionRepositoryProvider)
        .createMission(
          familyId: data.family.id,
          childId: result.childId,
          title: result.title,
          description: result.description,
          emoji: result.emoji,
          stars: result.stars,
          recurrence: result.recurrence,
          customDaysOfWeek: result.customDaysOfWeek,
          timeGroup: result.timeGroup,
          approvalMode: result.approvalMode,
          requiresPhoto: result.requiresPhoto,
        );
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missão criada!',
      message:
          '${mission.title} foi adicionada para ${data.childById(mission.childId)?.name ?? 'a criança'}.',
    );
  }

  Future<void> _openEditMissionSheet(Mission mission) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final result = await showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: TaskFormSheet(
            children: data.children,
            initialMission: mission,
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final updatedMission = await ref
        .read(missionRepositoryProvider)
        .updateMission(
          missionId: mission.id,
          childId: result.childId,
          title: result.title,
          description: result.description,
          emoji: result.emoji,
          stars: result.stars,
          recurrence: result.recurrence,
          customDaysOfWeek: result.customDaysOfWeek,
          timeGroup: result.timeGroup,
          approvalMode: result.approvalMode,
          requiresPhoto: result.requiresPhoto,
        );
    if (updatedMission == null) return;
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missão atualizada!',
      message: '${updatedMission.title} foi salva com sucesso.',
    );
  }

  Future<void> _archiveMission(Mission mission) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Arquivar missão?'),
          content: Text(
            '${mission.title} sairá das listas principais, mas o histórico antigo será preservado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true) return;

    final archivedMission = await ref
        .read(missionRepositoryProvider)
        .archiveMission(mission.id);
    if (archivedMission == null) return;
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Missão arquivada',
      message:
          '${archivedMission.title} foi removida das missões ativas e pode ser mantida no histórico.',
    );
  }

  Future<void> _restoreMission(Mission mission) async {
    final restoredMission = await ref
        .read(missionRepositoryProvider)
        .restoreMission(mission.id);
    if (restoredMission == null) return;
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missão restaurada!',
      message: '${restoredMission.title} voltou para as missões ativas.',
    );
  }

  Future<void> _openCreateRewardSheet() async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final result = await showModalBottomSheet<RewardFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: RewardDetailForm(children: data.children),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final reward = await ref
        .read(rewardRepositoryProvider)
        .createReward(
          familyId: data.family.id,
          childId: result.childId,
          title: result.title,
          description: result.description,
          emoji: result.emoji,
          cost: result.cost,
          renewal: result.renewal,
        );
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo criado!',
      message: '${reward.title} foi adicionado ao catálogo.',
    );
  }

  Future<void> _openEditRewardSheet(Reward reward) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final result = await showModalBottomSheet<RewardFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: RewardDetailForm(
            children: data.children,
            initialReward: reward,
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final updatedReward = await ref
        .read(rewardRepositoryProvider)
        .updateReward(
          rewardId: reward.id,
          childId: result.childId,
          title: result.title,
          description: result.description,
          emoji: result.emoji,
          cost: result.cost,
          renewal: result.renewal,
        );
    if (updatedReward == null) return;
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo atualizado!',
      message: '${updatedReward.title} foi salvo com sucesso.',
    );
  }

  Future<void> _archiveReward(Reward reward) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Arquivar mimo?'),
          content: Text(
            '${reward.title} sairá do catálogo principal, mas histórico e pedidos antigos serão preservados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true) return;

    final archivedReward = await ref
        .read(rewardRepositoryProvider)
        .archiveReward(reward.id);
    if (archivedReward == null) return;
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Mimo arquivado',
      message:
          '${archivedReward.title} foi removido do catálogo ativo e mantido no histórico.',
    );
  }

  Future<void> _restoreReward(Reward reward) async {
    final restoredReward = await ref
        .read(rewardRepositoryProvider)
        .restoreReward(reward.id);
    if (restoredReward == null) return;
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo restaurado!',
      message: '${restoredReward.title} voltou para o catálogo de mimos.',
    );
  }

  Future<void> _openPinSettings(AppSettings settings) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return ParentPinDialog.create(hasExistingPin: settings.hasParentPin);
      },
    );
    if (!mounted || pin == null) return;

    await ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(
          settings.copyWith(parentPin: pin, parentBiometricsEnabled: false),
        );
    if (!mounted) return;

    await ZeniSuccessPopup.show(
      context,
      title: settings.hasParentPin ? 'PIN alterado!' : 'PIN criado!',
      message: settings.hasParentPin
          ? 'O novo PIN já protege a entrada do modo responsável.'
          : 'O modo responsável agora pode ser protegido com PIN.',
    );
  }

  Future<void> _toggleParentBiometrics({
    required AppSettings settings,
    required bool enabled,
  }) async {
    if (!settings.hasParentPin) {
      await ZeniInfoPopup.show(
        context,
        title: 'Configure um PIN antes',
        message:
            'A biometria só pode ser ativada depois que você definir um PIN de 4 dígitos.',
      );
      return;
    }

    if (!enabled) {
      await ref
          .read(zeniAppStateControllerProvider.notifier)
          .updateAppSettings(settings.copyWith(parentBiometricsEnabled: false));
      return;
    }

    final availability = await ref
        .read(parentBiometricAuthProvider)
        .checkAvailability();
    if (!mounted) return;

    if (!availability.isAvailable) {
      await ZeniInfoPopup.show(
        context,
        title: 'Biometria indisponível',
        message: availability.message ?? parentBiometricsUnavailableMessage,
      );
      return;
    }

    await ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(settings.copyWith(parentBiometricsEnabled: true));
    if (!mounted) return;

    await ZeniSuccessPopup.show(
      context,
      title: 'Biometria ativada!',
      message: 'Na próxima entrada, tentaremos biometria antes do PIN.',
    );
  }

  Future<void> _approveMission(MissionLog log) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final child = data.childById(log.childId);
    if (child == null) return;

    await ref.read(missionRepositoryProvider).approveMissionLog(log.id);
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missão aprovada!',
      message: '${child.name} ganhou ${log.starsAwarded} estrelas.',
    );
  }

  Future<void> _rejectMission(MissionLog log) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final child = data.childById(log.childId);
    final mission = data.missionById(log.missionId);
    await ref.read(missionRepositoryProvider).rejectMissionLog(log.id);
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Missão rejeitada',
      message:
          '${mission?.title ?? 'A missão'} de ${child?.name ?? 'criança'} foi removida das aprovações.',
    );
  }

  Future<void> _rejectRewardRequest(RewardRequest request) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final child = data.childById(request.childId);
    final reward = data.rewardById(request.rewardId);

    if (child == null || reward == null) return;

    await ref.read(rewardRepositoryProvider).rejectRewardRequest(request.id);
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Pedido rejeitado',
      message:
          '${reward.title} foi rejeitado e ${reward.cost} estrelas voltaram para ${child.name}.',
    );
  }

  Future<void> _approveRewardRequest(RewardRequest request) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final child = data.childById(request.childId);
    final reward = data.rewardById(request.rewardId);
    await ref.read(rewardRepositoryProvider).approveRewardRequest(request.id);
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo aprovado!',
      message:
          '${reward?.title ?? 'O mimo'} de ${child?.name ?? 'criança'} foi aprovado.',
    );
  }

  Future<void> _approveMissionBatch(List<MissionLog> logs) async {
    if (logs.isEmpty) return;
    final totalStars = logs.fold<int>(0, (sum, log) => sum + log.starsAwarded);

    for (final log in logs) {
      await ref.read(missionRepositoryProvider).approveMissionLog(log.id);
    }
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missões aprovadas!',
      message: '${logs.length} missões liberaram $totalStars estrelas.',
    );
  }

  Future<void> _rejectMissionBatch(List<MissionLog> logs) async {
    if (logs.isEmpty) return;

    for (final log in logs) {
      await ref.read(missionRepositoryProvider).rejectMissionLog(log.id);
    }
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Missões rejeitadas',
      message: '${logs.length} missões foram removidas das aprovações.',
    );
  }

  Future<void> _approveRewardRequestBatch(List<RewardRequest> requests) async {
    if (requests.isEmpty) return;

    for (final request in requests) {
      await ref.read(rewardRepositoryProvider).approveRewardRequest(request.id);
    }
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Mimos aprovados!',
      message: '${requests.length} pedidos foram aprovados.',
    );
  }

  Future<void> _rejectRewardRequestBatch(List<RewardRequest> requests) async {
    if (requests.isEmpty) return;
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);
    var totalRefunded = 0;

    for (final request in requests) {
      final reward = data.rewardById(request.rewardId);
      totalRefunded += reward?.cost ?? 0;
      await ref.read(rewardRepositoryProvider).rejectRewardRequest(request.id);
    }
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Mimos rejeitados',
      message:
          '${requests.length} pedidos foram rejeitados e $totalRefunded estrelas foram devolvidas.',
    );
  }

  Future<void> _openCreateChildSheet() async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildParentModeData(appState);

    final result = await showModalBottomSheet<ParentChildFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: const ParentChildFormSheet(),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final child = await ref
        .read(familyRepositoryProvider)
        .createChild(
          familyId: data.family.id,
          name: result.name,
          emoji: result.emoji,
          birthDate: result.birthDate,
        );
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Criança adicionada!',
      message: '${child.name} agora faz parte da família.',
    );
  }

  Future<void> _openEditChildSheet(ChildProfile child) async {
    final appState = _currentAppState;
    if (appState == null) return;

    final result = await showModalBottomSheet<ParentChildFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ParentChildFormSheet(
            initialName: child.name,
            initialEmoji: child.emoji,
            initialBirthDate: child.birthDate,
            title: 'Editar perfil',
            submitLabel: 'Salvar perfil',
          ),
        );
      },
    );

    if (result == null) return;
    if (!mounted) return;

    final updatedChild = await ref
        .read(familyRepositoryProvider)
        .updateChild(
          childId: child.id,
          name: result.name,
          emoji: result.emoji,
          birthDate: result.birthDate,
        );
    if (updatedChild == null) return;
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Perfil atualizado!',
      message: '${updatedChild.name} foi atualizado com sucesso.',
    );
  }

  Future<void> _archiveChild(ChildProfile child) async {
    final appState = _currentAppState;
    if (appState == null) return;

    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Arquivar criança?'),
          content: Text(
            '${child.name} sairá das telas principais, mas histórico, saldo, missões e mimos serão mantidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true) return;
    if (!mounted) return;

    await ref.read(familyRepositoryProvider).archiveChild(child.id);
    if (!mounted) return;

    ZeniInfoPopup.show(
      context,
      title: 'Criança arquivada',
      message:
          '${child.name} foi removida das telas principais. O histórico foi preservado.',
    );
  }

  Future<void> _restoreChild(ChildProfile child) async {
    final restoredChild = child.copyWith(isActive: true);
    await ref.read(familyRepositoryProvider).restoreChild(child.id);
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Criança restaurada!',
      message: '${restoredChild.name} voltou para as telas principais.',
    );
  }

  Future<void> _openAccountSheet() async {
    final didAuthenticate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AuthAccountSheet(
            isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
          ),
        );
      },
    );

    if (!mounted || didAuthenticate != true) return;

    await ZeniSuccessPopup.show(
      context,
      title: 'Conta conectada!',
      message:
          'Sua conta foi vinculada neste aparelho. A sincronização virá em uma próxima etapa.',
    );
  }

  Future<void> _signOutAccount() async {
    final result = await ref.read(zeniAuthControllerProvider).signOut();
    if (!mounted) return;

    if (result.isSuccess) {
      await ZeniInfoPopup.show(
        context,
        title: 'Conta desconectada',
        message:
            'Sua sessão foi encerrada, mas a família e os dados locais continuam neste aparelho.',
      );
      return;
    }

    await ZeniInfoPopup.show(
      context,
      title: 'Não foi possível sair',
      message: result.message ?? 'Tente novamente em instantes.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(zeniAppStateControllerProvider);

    return appState.when(
      loading: () =>
          const ZeniScaffold(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const ZeniScaffold(
        child: Center(
          child: Text('Não foi possível carregar o modo responsável.'),
        ),
      ),
      data: (appData) {
        final data = _buildParentModeData(appData);
        final accessibility = ref.watch(zeniAccessibilityControllerProvider);
        final authState = ref.watch(authStateProvider);
        final remoteFamilySummary = ref
            .watch(remoteFamilySummaryProvider)
            .asData
            ?.value;
        final remoteChildren = ref.watch(remoteChildrenProvider).asData?.value;
        final remoteMissions = ref.watch(remoteMissionsProvider).asData?.value;
        final remoteRewards = ref.watch(remoteRewardsProvider).asData?.value;
        final remoteRewardRequests = ref
            .watch(remoteRewardRequestsProvider)
            .asData
            ?.value;
        final remoteStarLedger = ref
            .watch(remoteStarLedgerProvider)
            .asData
            ?.value;
        final remoteChildBalances = ref
            .watch(remoteChildBalancesProvider)
            .asData
            ?.value;
        final cloudConsistencyDiagnosticAsync = ref.watch(
          cloudConsistencyDiagnosticProvider,
        );
        final remoteMissionLogs = ref
            .watch(remoteMissionLogsProvider)
            .asData
            ?.value;
        final childBalanceDiagnostics =
            cloudConsistencyDiagnosticAsync
                .asData
                ?.value
                ?.childBalanceDiagnostics ??
            const [];
        final cloudConsistencyDiagnostic =
            cloudConsistencyDiagnosticAsync.asData?.value;
        final cloudConsistencyErrorText =
            cloudConsistencyDiagnosticAsync.asError != null
            ? 'Não foi possível conferir a nuvem agora.'
            : null;
        final historicalRestoreActionState =
            ref.watch(historicalRestoreActionStateProvider).asData?.value ??
            const HistoricalRestoreActionState(
              isVisible: false,
              isEnabled: false,
            );

        final pages = [
          _ParentDashboardPage(
            data: data,
            onOpenFamily: () {
              setState(() {
                _currentIndex = 3;
              });
            },
            onOpenMissionApprovals: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            onOpenMissions: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            onOpenRewardRequests: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          ParentMissionsTab(
            activeChildren: data.activeChildren,
            activeMissions: data.activeMissions,
            archivedMissions: data.archivedMissions,
            awaitingLogs: data.awaitingLogs,
            childById: data.childById,
            missionById: data.missionById,
            onApproveMission: _approveMission,
            onRejectMission: _rejectMission,
            onApproveMissionBatch: _approveMissionBatch,
            onRejectMissionBatch: _rejectMissionBatch,
            onEditMission: _openEditMissionSheet,
            onArchiveMission: _archiveMission,
            onRestoreMission: _restoreMission,
          ),
          ParentRewardsTab(
            activeChildren: data.activeChildren,
            activeRewards: data.activeRewards,
            archivedRewards: data.archivedRewards,
            pendingRequests: data.pendingRequests,
            childById: data.childById,
            rewardById: data.rewardById,
            onApproveRewardRequest: _approveRewardRequest,
            onRejectRewardRequest: _rejectRewardRequest,
            onApproveRewardRequestBatch: _approveRewardRequestBatch,
            onRejectRewardRequestBatch: _rejectRewardRequestBatch,
            onEditReward: _openEditRewardSheet,
            onArchiveReward: _archiveReward,
            onRestoreReward: _restoreReward,
          ),
          ParentFamilyTab(
            family: data.family,
            children: data.children,
            members: data.members,
            activeMissions: data.activeMissions,
            activeRewards: data.activeRewards,
            ledgerEntries: data.ledgerEntries,
            onAddChild: _openCreateChildSheet,
            onEditChild: _openEditChildSheet,
            onArchiveChild: _archiveChild,
            onRestoreChild: _restoreChild,
          ),
          ParentSettingsTab(
            appSettings: appData.appSettings,
            accessibilitySettings: accessibility.settings,
            onThemeModeChanged: accessibility.setThemeModeOption,
            onDyslexiaFontChanged: accessibility.setDyslexiaFontEnabled,
            onTextScaleChanged: accessibility.setTextScale,
            onVibrationChanged: accessibility.setVibrationEnabled,
            onNotificationsChanged: accessibility.setNotificationsEnabled,
            onTtsChanged: accessibility.setTtsEnabled,
            onReadAloudByChildProfileChanged:
                accessibility.setReadAloudByChildProfile,
            onConfigurePin: () => _openPinSettings(appData.appSettings),
            onBiometricsChanged: (value) => _toggleParentBiometrics(
              settings: appData.appSettings,
              enabled: value,
            ),
            authState: authState,
            remoteFamilySummary: remoteFamilySummary,
            localChildrenCount: data.children.length,
            remoteChildrenCount: remoteChildren?.length,
            localMissionsCount: data.missions.length,
            remoteMissionsCount: remoteMissions?.length,
            localRewardsCount: data.rewards.length,
            remoteRewardsCount: remoteRewards?.length,
            localMissionLogsCount: appData.missionLogs.length,
            remoteMissionLogsCount: remoteMissionLogs?.length,
            localRewardRequestsCount: appData.rewardRequests.length,
            remoteRewardRequestsCount: remoteRewardRequests?.length,
            localStarLedgerCount: appData.starLedgerEntries.length,
            remoteStarLedgerCount: remoteStarLedger?.length,
            childBalanceDiagnostics: childBalanceDiagnostics,
            hasRemoteChildBalanceData: remoteChildBalances != null,
            cloudConsistencyDiagnostic: cloudConsistencyDiagnostic,
            cloudConsistencyErrorText: cloudConsistencyErrorText,
            lastChildrenSyncAt: appData.appSettings.lastChildrenSyncAt,
            lastMissionsSyncAt: appData.appSettings.lastMissionsSyncAt,
            lastRewardsSyncAt: appData.appSettings.lastRewardsSyncAt,
            lastMissionLogsSyncAt: appData.appSettings.lastMissionLogsSyncAt,
            lastRewardRequestsSyncAt:
                appData.appSettings.lastRewardRequestsSyncAt,
            lastStarLedgerSyncAt: appData.appSettings.lastStarLedgerSyncAt,
            lastFullSyncAt: appData.appSettings.lastFullSyncAt,
            isSupabaseConfigured: ZeniSupabaseBootstrap.state.isConfigured,
            showHistoricalRestoreAction:
                historicalRestoreActionState.isVisible,
            canRunHistoricalRestore: historicalRestoreActionState.isEnabled,
            onOpenAccount: _openAccountSheet,
            onSignOut: _signOutAccount,
            onUpdateRemoteFamilyName: ({required familyId, required name}) {
              return ref
                  .read(zeniAccountControllerProvider)
                  .updateRemoteFamilyName(familyId: familyId, name: name);
            },
            onSyncCloudData: () {
              return ref
                  .read(zeniCloudSyncControllerProvider)
                  .syncCloudDataNow();
            },
            onHistoricalRestore: () {
              return ref
                  .read(historicalRestoreControllerProvider)
                  .restoreHistoryIfSafe();
            },
          ),
        ];

        return ZeniScaffold(
          appBar: ZeniTopBar(
            title: 'Responsável',
            subtitle: data.family.name,
            actions: [
              IconButton(
                tooltip: 'Trocar perfil',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  context.go('/');
                },
              ),
              const SizedBox(width: ZeniSpacing.sm),
              ZeniIconActionButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notificações',
                tone: ZeniIconActionTone.primary,
                onPressed: () {
                  ZeniInfoPopup.show(
                    context,
                    title: 'Notificações',
                    message:
                        'Aqui entrarão aprovações de missões, pedidos de mimos e lembretes.',
                  );
                },
              ),
              const SizedBox(width: ZeniSpacing.sm),
            ],
          ),
          floatingActionButton: _currentIndex == 1 || _currentIndex == 2
              ? ZeniFab(
                  icon: Icons.add_rounded,
                  label: _currentIndex == 1 ? 'Missão' : 'Mimo',
                  tooltip: _currentIndex == 1 ? 'Criar missão' : 'Criar mimo',
                  onPressed: _currentIndex == 1
                      ? _openCreateMissionSheet
                      : _openCreateRewardSheet,
                )
              : null,
          bottomNavigationBar: ZeniBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              ZeniBottomNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Início',
              ),
              ZeniBottomNavItem(
                icon: Icons.check_circle_outline_rounded,
                selectedIcon: Icons.check_circle_rounded,
                label: 'Missões',
              ),
              ZeniBottomNavItem(
                icon: Icons.card_giftcard_outlined,
                selectedIcon: Icons.card_giftcard_rounded,
                label: 'Mimos',
              ),
              ZeniBottomNavItem(
                icon: Icons.family_restroom_outlined,
                selectedIcon: Icons.family_restroom_rounded,
                label: 'Família',
              ),
              ZeniBottomNavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Ajustes',
              ),
            ],
          ),
          child: IndexedStack(index: _currentIndex, children: pages),
        );
      },
    );
  }
}

class _ParentDashboardPage extends StatelessWidget {
  const _ParentDashboardPage({
    required this.data,
    required this.onOpenFamily,
    required this.onOpenMissionApprovals,
    required this.onOpenMissions,
    required this.onOpenRewardRequests,
  });

  final _ParentModeData data;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenMissionApprovals;
  final VoidCallback onOpenMissions;
  final VoidCallback onOpenRewardRequests;
  static const MonthlyStarProjectionCalculator _projectionCalculator =
      MonthlyStarProjectionCalculator();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Painel do responsável',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Acompanhe missões, aprovações, mimos e evolução da família.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ParentMetricCard(
                  emoji: '👧',
                  value: '${data.activeChildren.length}',
                  label: 'crianças',
                  onTap: onOpenFamily,
                ),
              ),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: ParentMetricCard(
                  emoji: '⏳',
                  value: '${data.awaitingLogs.length}',
                  label: 'aprovações',
                  onTap: onOpenMissionApprovals,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.md),
          Row(
            children: [
              Expanded(
                child: ParentMetricCard(
                  emoji: '✅',
                  value: '${data.activeMissions.length}',
                  label: 'missões ativas',
                  onTap: onOpenMissions,
                ),
              ),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: ParentMetricCard(
                  emoji: '🎁',
                  value: '${data.pendingRequests.length}',
                  label: 'mimos pedidos',
                  onTap: onOpenRewardRequests,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Text('Crianças', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          for (final child in data.activeChildren) ...[
            ParentChildSummaryCard(child: child, onTap: onOpenFamily),
            const SizedBox(height: ZeniSpacing.sm),
            MonthlyStarProjectionCard(
              child: child,
              projection: _projectionCalculator.calculateForChild(
                child: child,
                activeMissions: data.activeMissions,
              ),
            ),
            const SizedBox(height: ZeniSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ParentModeData {
  const _ParentModeData({
    required this.family,
    required this.children,
    required this.members,
    required this.missions,
    required this.awaitingLogs,
    required this.rewards,
    required this.pendingRequests,
    required this.ledgerEntries,
  });

  final Family family;
  final List<ChildProfile> children;
  final List<FamilyMember> members;
  List<ChildProfile> get activeChildren =>
      children.where((child) => child.isActive).toList();

  final List<Mission> missions;
  List<Mission> get activeMissions =>
      missions.where((mission) => mission.isActive).toList();
  List<Mission> get archivedMissions => missions
      .where((mission) => mission.status == MissionStatus.archived)
      .toList();
  final List<MissionLog> awaitingLogs;
  final List<Reward> rewards;
  List<Reward> get activeRewards =>
      rewards.where((reward) => reward.isActive).toList();
  List<Reward> get archivedRewards =>
      rewards.where((reward) => !reward.isActive).toList();
  final List<RewardRequest> pendingRequests;
  final List<StarLedgerEntry> ledgerEntries;

  ChildProfile? childById(String childId) {
    for (final child in children) {
      if (child.id == childId) return child;
    }

    return null;
  }

  Mission? missionById(String missionId) {
    for (final mission in missions) {
      if (mission.id == missionId) return mission;
    }

    return null;
  }

  Reward? rewardById(String rewardId) {
    for (final reward in rewards) {
      if (reward.id == rewardId) return reward;
    }

    return null;
  }

  _ParentModeData copyWith({
    Family? family,
    List<ChildProfile>? children,
    List<FamilyMember>? members,
    List<Mission>? missions,
    List<MissionLog>? awaitingLogs,
    List<Reward>? rewards,
    List<RewardRequest>? pendingRequests,
    List<StarLedgerEntry>? ledgerEntries,
  }) {
    return _ParentModeData(
      family: family ?? this.family,
      children: children ?? this.children,
      members: members ?? this.members,
      missions: missions ?? this.missions,
      awaitingLogs: awaitingLogs ?? this.awaitingLogs,
      rewards: rewards ?? this.rewards,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
    );
  }
}

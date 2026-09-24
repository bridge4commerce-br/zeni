import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/zeni_accessibility_controller.dart';
import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/feedback/zeni_haptics.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/providers/zeni_repository_providers.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_choice_chip.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_fab.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_bottom_nav_bar.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
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
import '../../../sync/domain/pending_sync_notification.dart';
import '../../../sync/presentation/providers/cloud_consistency_providers.dart';
import '../../../sync/presentation/providers/cloud_sync_providers.dart';
import '../../../sync/presentation/providers/device_bootstrap_providers.dart';
import '../../../sync/presentation/providers/historical_restore_providers.dart';
import '../../../sync/presentation/providers/opportunistic_sync_providers.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../../../smart_content/presentation/pages/smart_suggestions_page.dart';
import '../widgets/monthly_star_projection_card.dart';
import '../widgets/mission_approval_card.dart';
import '../widgets/parent_child_form_sheet.dart';
import '../widgets/parent_family_tab.dart';
import '../widgets/parent_missions_tab.dart';
import '../widgets/parent_rewards_tab.dart';
import '../widgets/parent_settings_tab.dart';
import '../widgets/reward_request_card.dart';

class ParentShellPage extends ConsumerStatefulWidget {
  const ParentShellPage({super.key});

  @override
  ConsumerState<ParentShellPage> createState() => _ParentShellPageState();
}

class _ParentShellPageState extends ConsumerState<ParentShellPage> {
  int _currentIndex = 0;
  bool _isDiscoveringMissions = false;

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

  Future<void> _openCreateMissionSheet({
    TaskFormInitialValues? initialValues,
  }) async {
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
            initialValues: initialValues,
          ),
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_create_mission');
    await ref.read(zeniHapticsProvider).confirm();
    if (!mounted) return;

    ZeniSuccessPopup.show(
      context,
      title: 'Missão criada!',
      message:
          '${mission.title} foi adicionada para ${data.childById(mission.childId)?.name ?? 'a criança'}.',
    );
  }

  Future<SmartBatchCreationResult> _createSuggestedMissions(
    String familyId,
    List<SmartBatchMissionDraft> drafts,
    List<ChildProfile> children,
  ) async {
    final repository = ref.read(missionRepositoryProvider);
    final current = _currentAppState;
    final active =
        current?.missions.where((mission) => mission.isActive).toList() ??
        const <Mission>[];
    var created = 0;
    var skipped = 0;
    final known = <String>{
      for (final mission in active)
        '${mission.childId}:${mission.title.trim().toLowerCase()}',
    };
    for (final child in children) {
      for (final draft in drafts) {
        final key = '${child.id}:${draft.title.trim().toLowerCase()}';
        if (!known.add(key)) {
          skipped += 1;
          continue;
        }
        await repository.createMission(
          familyId: familyId,
          childId: child.id,
          title: draft.title,
          description: draft.description,
          emoji: draft.emoji,
          stars: draft.stars,
          recurrence: draft.recurrence,
          customDaysOfWeek: draft.customDaysOfWeek,
          timeGroup: draft.timeGroup,
          approvalMode: draft.approvalMode,
          requiresPhoto: false,
        );
        created += 1;
      }
    }
    if (created > 0) {
      ref
          .read(zeniOpportunisticSyncControllerProvider)
          .scheduleSync(reason: 'parent_create_smart_missions_batch');
    }
    return SmartBatchCreationResult(created: created, skipped: skipped);
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_update_mission');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_archive_mission');
    await ref.read(zeniHapticsProvider).cancel();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_restore_mission');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_create_reward');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_update_reward');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_archive_reward');
    await ref.read(zeniHapticsProvider).cancel();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_restore_reward');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_approve_mission');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_reject_mission');
    await ref.read(zeniHapticsProvider).cancel();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_reject_reward');
    await ref.read(zeniHapticsProvider).cancel();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_approve_reward');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_approve_mission_batch');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_reject_mission_batch');
    await ref.read(zeniHapticsProvider).cancel();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_approve_reward_batch');
    await ref.read(zeniHapticsProvider).confirm();
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

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_reject_reward_batch');
    await ref.read(zeniHapticsProvider).cancel();
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

    final form = ParentChildFormSheet(
      showDragHandle: !ZeniAdaptiveModal.usesDialog(context),
    );
    final result = ZeniAdaptiveModal.usesDialog(context)
        ? await showDialog<ParentChildFormResult>(
            context: context,
            builder: (_) => Dialog(child: ZeniAdaptiveModalFrame(child: form)),
          )
        : await showModalBottomSheet<ParentChildFormResult>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: form,
            ),
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
          avatarId: result.avatarId,
          ttsEnabled: result.ttsEnabled,
        );
    if (!mounted) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_create_child');
    await ref.read(zeniHapticsProvider).confirm();
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

    final form = ParentChildFormSheet(
      initialName: child.name,
      initialEmoji: child.emoji,
      initialBirthDate: child.birthDate,
      initialAvatarId: child.avatarId,
      initialTtsEnabled: child.ttsEnabled,
      title: 'Editar perfil',
      submitLabel: 'Salvar perfil',
      showDragHandle: !ZeniAdaptiveModal.usesDialog(context),
    );
    final result = ZeniAdaptiveModal.usesDialog(context)
        ? await showDialog<ParentChildFormResult>(
            context: context,
            builder: (_) => Dialog(child: ZeniAdaptiveModalFrame(child: form)),
          )
        : await showModalBottomSheet<ParentChildFormResult>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: form,
            ),
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
          avatarId: result.avatarId,
          ttsEnabled: result.ttsEnabled,
        );
    if (updatedChild == null) return;
    if (!mounted) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'parent_update_child');
    await ref.read(zeniHapticsProvider).confirm();
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
            bootstrapState: ZeniSupabaseBootstrap.state,
          ),
        );
      },
    );

    if (!mounted || didAuthenticate != true) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .syncNowBestEffort(reason: 'parent_login_completed');

    await ZeniSuccessPopup.show(
      context,
      title: 'Conta conectada!',
      message:
          'Sua conta foi vinculada neste aparelho. O app continuará salvando localmente e tentará sincronizar quando a nuvem estiver disponível.',
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

  Future<void> _confirmAndClearLocalDeviceData() async {
    final didClear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _ClearLocalDeviceDataSheet(
            onConfirm: () async {
              await ref
                  .read(zeniAppStateControllerProvider.notifier)
                  .clearLocalDeviceData();
            },
          ),
        );
      },
    );

    if (!mounted || didClear != true) return;
    context.go('/');
  }

  Future<void> _refreshPrimaryLists() async {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      final result = await _syncCloudDataAndNotifyIfNeeded();
      if (!mounted || result.isSuccess || result.message == null) {
        return;
      }

      await ZeniInfoPopup.show(
        context,
        title: 'Sincronização',
        message: result.message!,
      );
      return;
    }

    ref.invalidate(zeniAppStateControllerProvider);
    await ref.read(zeniAppStateControllerProvider.future);
  }

  Future<ZeniCloudSyncResult> _syncCloudDataAndNotifyIfNeeded() async {
    final beforeState = await ref.read(zeniAppStateControllerProvider.future);
    final result = await ref
        .read(zeniCloudSyncControllerProvider)
        .syncNowManually();
    if (!result.isSuccess || !mounted) {
      return result;
    }

    final afterState = await ref.read(zeniAppStateControllerProvider.future);
    await _showNewPendingNoticesIfNeeded(
      beforeState: beforeState,
      afterState: afterState,
    );
    return result;
  }

  Future<void> _showNewPendingNoticesIfNeeded({
    required ZeniAppState beforeState,
    required ZeniAppState afterState,
  }) async {
    if (!afterState.appSettings.notificationsEnabled) {
      return;
    }

    final plan = buildPendingSyncNotificationPlan(
      previousState: beforeState,
      currentState: afterState,
    );
    for (final notice in plan.notices) {
      if (!mounted) return;
      await ZeniInfoPopup.show(
        context,
        title: notice.title,
        message: notice.message,
      );
    }
  }

  Future<void> _openManageAccountAndDataSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ManageAccountAndDataSheet(
          onClearLocalDeviceData: () async {
            Navigator.of(sheetContext).pop();
            await _confirmAndClearLocalDeviceData();
          },
        );
      },
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
              showAction: false,
              isEnabled: false,
              message: null,
            );
        final deviceBootstrapActionState =
            ref.watch(deviceBootstrapActionStateProvider).asData?.value ??
            const DeviceBootstrapActionState(
              isVisible: false,
              showAction: false,
              isEnabled: false,
              message: null,
            );
        final pendingNotificationCount =
            data.awaitingLogs.length + data.pendingRequests.length;

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
            onApproveMission: _approveMission,
            onRejectMission: _rejectMission,
            onApproveRewardRequest: _approveRewardRequest,
            onRejectRewardRequest: _rejectRewardRequest,
            onRefresh: _refreshPrimaryLists,
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
            onConfirmSuggestedMissions: (drafts, children) =>
                _createSuggestedMissions(data.family.id, drafts, children),
            onDiscoveringChanged: (isDiscovering) {
              setState(() => _isDiscoveringMissions = isDiscovering);
            },
            onRefresh: _refreshPrimaryLists,
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
            onRefresh: _refreshPrimaryLists,
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
            onUpdateParentDisplayName: (name) {
              return ref
                  .read(zeniAppStateControllerProvider.notifier)
                  .updateParentDisplayName(name);
            },
          ),
          ParentSettingsTab(
            parentDisplayName: _parentDisplayName(data.members),
            appSettings: appData.appSettings,
            accessibilitySettings: accessibility.settings,
            onThemeModeChanged: accessibility.setThemeModeOption,
            onDyslexiaFontChanged: accessibility.setDyslexiaFontEnabled,
            onTextScaleChanged: (value) => ref
                .read(zeniAccessibilityControllerProvider)
                .setTextScale(value),
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
            supabaseBootstrapState: ZeniSupabaseBootstrap.state,
            isGoogleSignInAvailable: ref.watch(googleSignInAvailableProvider),
            isAppleSignInAvailable: ref.watch(appleSignInAvailableProvider),
            showHistoricalRestoreStatus: historicalRestoreActionState.isVisible,
            showDeviceBootstrapStatus: deviceBootstrapActionState.isVisible,
            showDeviceBootstrapAction: deviceBootstrapActionState.showAction,
            canRunDeviceBootstrap: deviceBootstrapActionState.isEnabled,
            deviceBootstrapMessage: deviceBootstrapActionState.message,
            showHistoricalRestoreAction:
                historicalRestoreActionState.showAction,
            canRunHistoricalRestore: historicalRestoreActionState.isEnabled,
            historicalRestoreMessage: historicalRestoreActionState.message,
            onOpenAccount: _openAccountSheet,
            onSignOut: _signOutAccount,
            onManageAccountAndData: _openManageAccountAndDataSheet,
            onClearLocalDeviceData: _confirmAndClearLocalDeviceData,
            onUpdateParentDisplayName: (name) {
              return ref
                  .read(zeniAppStateControllerProvider.notifier)
                  .updateParentDisplayName(name);
            },
            onUpdateRemoteFamilyName: ({required familyId, required name}) {
              return ref
                  .read(zeniAccountControllerProvider)
                  .updateRemoteFamilyName(familyId: familyId, name: name);
            },
            onSyncCloudData: () {
              return _syncCloudDataAndNotifyIfNeeded();
            },
            onDeviceBootstrap: () {
              return ref
                  .read(deviceBootstrapControllerProvider)
                  .bootstrapFromRemoteFamily();
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
              Semantics(
                button: true,
                label: 'Trocar perfil',
                child: ZeniIconActionButton(
                  icon: Icons.swap_horiz_rounded,
                  tooltip: 'Trocar perfil',
                  tone: ZeniIconActionTone.neutral,
                  onPressed: () {
                    ref.read(zeniHapticsProvider).selection();
                    context.go('/');
                  },
                ),
              ),
              const SizedBox(width: ZeniSpacing.sm),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ZeniIconActionButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notificações',
                    tone: ZeniIconActionTone.primary,
                    onPressed: () {
                      ref.read(zeniHapticsProvider).selection();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) {
                          return _PendingNotificationsSheet(data: data);
                        },
                      );
                    },
                  ),
                  if (pendingNotificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: _PendingBadge(count: pendingNotificationCount),
                    ),
                ],
              ),
              const SizedBox(width: ZeniSpacing.sm),
            ],
          ),
          floatingActionButton:
              (_currentIndex == 1 && !_isDiscoveringMissions) ||
                  _currentIndex == 2
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
              ref.read(zeniHapticsProvider).selection();
              setState(() {
                _currentIndex = index;
                if (index != 1) _isDiscoveringMissions = false;
              });
            },
            items: [
              ZeniBottomNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Início',
              ),
              ZeniBottomNavItem(
                icon: Icons.check_circle_outline_rounded,
                selectedIcon: Icons.check_circle_rounded,
                label: 'Missões',
                badgeCount: data.awaitingLogs.length,
              ),
              ZeniBottomNavItem(
                icon: Icons.card_giftcard_outlined,
                selectedIcon: Icons.card_giftcard_rounded,
                label: 'Mimos',
                badgeCount: data.pendingRequests.length,
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

  String _parentDisplayName(List<FamilyMember> members) {
    final parent = members
        .where((member) => member.role == ZeniUserRole.parent)
        .fold<FamilyMember?>(null, (selected, member) {
          if (selected == null) {
            return member;
          }
          if (!selected.isOwner && member.isOwner) {
            return member;
          }
          return selected;
        });
    final name = parent?.name.trim() ?? '';
    return name.isEmpty ? 'Responsável' : name;
  }
}

class _ParentDashboardPage extends StatelessWidget {
  const _ParentDashboardPage({
    required this.data,
    required this.onOpenFamily,
    required this.onOpenMissionApprovals,
    required this.onOpenMissions,
    required this.onOpenRewardRequests,
    required this.onApproveMission,
    required this.onRejectMission,
    required this.onApproveRewardRequest,
    required this.onRejectRewardRequest,
    required this.onRefresh,
  });

  final _ParentModeData data;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenMissionApprovals;
  final VoidCallback onOpenMissions;
  final VoidCallback onOpenRewardRequests;
  final Future<void> Function(MissionLog log) onApproveMission;
  final Future<void> Function(MissionLog log) onRejectMission;
  final Future<void> Function(RewardRequest request) onApproveRewardRequest;
  final Future<void> Function(RewardRequest request) onRejectRewardRequest;
  final Future<void> Function() onRefresh;
  static const MonthlyStarProjectionCalculator _projectionCalculator =
      MonthlyStarProjectionCalculator();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: ZeniSpacing.spaceGroup,
          bottom: ZeniSpacing.spaceCanvas,
        ),
        child: ZeniPageFrame(
          key: const Key('parent-dashboard-frame'),
          width: ZeniPageWidth.dashboard,
          child: LayoutBuilder(
            builder: (context, _) {
              final layout = _ParentDashboardLayout.fromContext(context);
              final metrics = [
                _DashboardMetricItem(
                  metricKey: const Key('parent-dashboard-metric-children'),
                  icon: Icons.family_restroom_outlined,
                  value: '${data.activeChildren.length}',
                  label: 'crianças',
                  onTap: onOpenFamily,
                ),
                _DashboardMetricItem(
                  metricKey: const Key('parent-dashboard-metric-approvals'),
                  icon: Icons.pending_actions_outlined,
                  value: '${data.awaitingLogs.length}',
                  label: 'aprovações',
                  onTap: onOpenMissionApprovals,
                ),
                _DashboardMetricItem(
                  metricKey: const Key('parent-dashboard-metric-missions'),
                  icon: Icons.task_alt_rounded,
                  value: '${data.activeMissions.length}',
                  label: 'missões ativas',
                  onTap: onOpenMissions,
                ),
                _DashboardMetricItem(
                  metricKey: const Key('parent-dashboard-metric-rewards'),
                  icon: Icons.card_giftcard_outlined,
                  value: '${data.pendingRequests.length}',
                  label: 'mimos pedidos',
                  onTap: onOpenRewardRequests,
                ),
              ];

              return SizedBox(
                key: const Key('parent-dashboard-content'),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DashboardHeader(),
                    if (data.pendingCount > 0) ...[
                      const SizedBox(height: ZeniSpacing.spaceGroup),
                      _PendingTodaySection(
                        data: data,
                        onApproveMission: onApproveMission,
                        onRejectMission: onRejectMission,
                        onApproveRewardRequest: onApproveRewardRequest,
                        onRejectRewardRequest: onRejectRewardRequest,
                      ),
                    ],
                    const SizedBox(height: ZeniSpacing.spaceGroup),
                    _ParentMetricGrid(
                      columns: layout.metricColumns,
                      children: metrics,
                    ),
                    const SizedBox(height: ZeniSpacing.spaceSection),
                    _ParentChildrenDashboard(
                      isSideBySide: layout.usesDetailColumns,
                      children: data.activeChildren,
                      projectionFor: (child) =>
                          _projectionCalculator.calculateForChild(
                            child: child,
                            activeMissions: data.activeMissions,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ParentDashboardLayout {
  const _ParentDashboardLayout({
    required this.metricColumns,
    required this.usesDetailColumns,
  });

  final int metricColumns;
  final bool usesDetailColumns;

  factory _ParentDashboardLayout.fromContext(BuildContext context) {
    final windowClass = ZeniResponsive.windowClass(context);
    return _ParentDashboardLayout(
      metricColumns: windowClass == ZeniWindowClass.large ? 4 : 2,
      usesDetailColumns: switch (windowClass) {
        ZeniWindowClass.expanded || ZeniWindowClass.large => true,
        ZeniWindowClass.compact || ZeniWindowClass.medium => false,
      },
    );
  }
}

class _ParentMetricGrid extends StatelessWidget {
  const _ParentMetricGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ZeniSurface(
    key: const Key('parent-dashboard-metrics'),
    role: ZeniSurfaceRole.grouped,
    mode: ZeniVisualMode.parent,
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) const _DashboardDivider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++) ...[
                Expanded(
                  child: start + column < children.length
                      ? children[start + column]
                      : const SizedBox.shrink(),
                ),
                if (column < columns - 1)
                  const SizedBox(width: ZeniSpacing.spaceInline),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Painel do responsável', style: typography.pageTitle),
          const SizedBox(height: ZeniSpacing.spaceInline),
          Text(
            'Acompanhe missões, aprovações, mimos e evolução da família.',
            style: typography.body,
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricItem extends StatelessWidget {
  const _DashboardMetricItem({
    required this.metricKey,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final Key metricKey;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Semantics(
      button: true,
      label: '$value $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            key: metricKey,
            padding: const EdgeInsets.symmetric(
              horizontal: ZeniSpacing.spaceControl,
              vertical: ZeniSpacing.spaceControl,
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.actionPrimary),
                const SizedBox(width: ZeniSpacing.spaceControl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: typography.sectionTitle),
                      const SizedBox(height: ZeniSpacing.spaceInlineTight),
                      Text(label, style: typography.metadata),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentChildrenDashboard extends StatefulWidget {
  const _ParentChildrenDashboard({
    required this.isSideBySide,
    required this.children,
    required this.projectionFor,
  });

  final bool isSideBySide;
  final List<ChildProfile> children;
  final MonthlyStarProjectionResult Function(ChildProfile child) projectionFor;

  @override
  State<_ParentChildrenDashboard> createState() =>
      _ParentChildrenDashboardState();
}

class _ParentChildrenDashboardState extends State<_ParentChildrenDashboard> {
  String? _selectedChildId;

  @override
  void didUpdateWidget(covariant _ParentChildrenDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.children.any((child) => child.id == _selectedChildId)) {
      _selectedChildId = null;
    }
  }

  ChildProfile? get _selectedChild {
    if (widget.children.isEmpty) return null;
    return widget.children.firstWhere(
      (child) => child.id == _selectedChildId,
      orElse: () => widget.children.first,
    );
  }

  void _selectChild(String childId) {
    if (_selectedChildId == childId) return;
    setState(() {
      _selectedChildId = childId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = _selectedChild;
    if (selectedChild == null) return const SizedBox.shrink();

    final projectionPanel = MonthlyStarProjectionCard(
      key: const Key('parent-dashboard-monthly-projection'),
      child: selectedChild,
      projection: widget.projectionFor(selectedChild),
      childSelector: widget.children.length < 2
          ? null
          : _ProjectionChildSelector(
              selectedChildId: selectedChild.id,
              children: widget.children,
              onChanged: _selectChild,
            ),
    );
    final childrenList = Column(
      key: const Key('parent-dashboard-children-column'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardSectionHeader(
          title: 'Crianças',
          subtitle: 'Saldo e sequência local de cada perfil.',
        ),
        const SizedBox(height: ZeniSpacing.spaceCard),
        ZeniSurface(
          role: ZeniSurfaceRole.grouped,
          mode: ZeniVisualMode.parent,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < widget.children.length; index++) ...[
                _DashboardChildRow(
                  child: widget.children[index],
                  isSelected: widget.children[index].id == selectedChild.id,
                  onTap: () => _selectChild(widget.children[index].id),
                ),
                if (index < widget.children.length - 1)
                  const _DashboardDivider(),
              ],
            ],
          ),
        ),
      ],
    );

    if (!widget.isSideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          childrenList,
          const SizedBox(height: ZeniSpacing.spaceSection),
          projectionPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: childrenList),
        const SizedBox(width: ZeniSpacing.spaceGroup),
        Expanded(
          flex: 2,
          child: Column(
            key: const Key('parent-dashboard-projections-column'),
            children: [projectionPanel],
          ),
        ),
      ],
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceInlineTight),
        Text(subtitle, style: typography.metadata),
      ],
    );
  }
}

class _DashboardChildRow extends StatelessWidget {
  const _DashboardChildRow({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final ChildProfile child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${child.name}, ${child.starBalance} estrelas, ${child.streakCount} dias de sequência',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            key: Key('parent-dashboard-child-${child.id}'),
            padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: ZeniAvatar(
                    label: child.name,
                    emoji: child.emoji,
                    size: 44,
                  ),
                ),
                const SizedBox(width: ZeniSpacing.spaceControl),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                child.name,
                                style: typography.cardTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: ZeniSpacing.spaceInline),
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.actionPrimary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: ZeniSpacing.spaceInlineTight),
                        Text(
                          '${child.streakCount} dias de sequência',
                          style: typography.metadata,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ZeniSpacing.spaceInline),
                ExcludeSemantics(
                  child: Text(
                    '${child.starBalance} ⭐',
                    style: typography.bodyEmphasis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardDivider extends StatelessWidget {
  const _DashboardDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: ZeniSpacing.spaceCard,
    endIndent: ZeniSpacing.spaceCard,
    color: context.zeniColors.borderSubtle,
  );
}

class _ProjectionChildSelector extends StatelessWidget {
  const _ProjectionChildSelector({
    required this.selectedChildId,
    required this.children,
    required this.onChanged,
  });

  final String selectedChildId;
  final List<ChildProfile> children;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('parent-dashboard-projection-selector'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children) ...[
            ZeniChoiceChip(
              label: child.name,
              icon: Text(child.emoji),
              selected: child.id == selectedChildId,
              onSelected: (_) => onChanged(child.id),
              mode: ZeniVisualMode.parent,
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
          ],
        ],
      ),
    );
  }
}

class _PendingNotificationsSheet extends StatelessWidget {
  const _PendingNotificationsSheet({required this.data});

  final _ParentModeData data;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Pendências do responsável',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Missões enviadas e pedidos de mimo aparecem aqui até serem resolvidos.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          if (data.awaitingLogs.isEmpty && data.pendingRequests.isEmpty)
            const Text('Nenhuma pendência no momento.')
          else ...[
            if (data.awaitingLogs.isNotEmpty) ...[
              Text(
                'Missões aguardando aprovação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeniSpacing.sm),
              for (final log in data.awaitingLogs) ...[
                Text(
                  '• ${data.childById(log.childId)?.name ?? 'Criança'} enviou ${data.missionById(log.missionId)?.title ?? 'uma missão'}',
                ),
                const SizedBox(height: ZeniSpacing.xs),
              ],
              const SizedBox(height: ZeniSpacing.md),
            ],
            if (data.pendingRequests.isNotEmpty) ...[
              Text(
                'Pedidos de mimo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeniSpacing.sm),
              for (final request in data.pendingRequests) ...[
                Text(
                  '• ${data.childById(request.childId)?.name ?? 'Criança'} pediu ${data.rewardById(request.rewardId)?.title ?? 'um mimo'}',
                ),
                const SizedBox(height: ZeniSpacing.xs),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      key: const Key('parent-pending-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PendingTodaySection extends StatelessWidget {
  const _PendingTodaySection({
    required this.data,
    required this.onApproveMission,
    required this.onRejectMission,
    required this.onApproveRewardRequest,
    required this.onRejectRewardRequest,
  });

  final _ParentModeData data;
  final Future<void> Function(MissionLog log) onApproveMission;
  final Future<void> Function(MissionLog log) onRejectMission;
  final Future<void> Function(RewardRequest request) onApproveRewardRequest;
  final Future<void> Function(RewardRequest request) onRejectRewardRequest;

  @override
  Widget build(BuildContext context) {
    final pendingCount = data.pendingCount;
    final title = pendingCount == 1
        ? 'Você tem 1 pendência'
        : 'Você tem $pendingCount pendências';

    return Column(
      key: const Key('parent-pending-today-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendências de hoje',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: ZeniSpacing.xs),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
        ),
        const SizedBox(height: ZeniSpacing.lg),
        for (final log in data.awaitingLogs) ...[
          Text(
            '${data.childById(log.childId)?.name ?? 'Criança'} enviou uma missão',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ZeniSpacing.xs),
          MissionApprovalCard(
            key: Key('parent-pending-mission-${log.id}'),
            log: log,
            mission: data.missionById(log.missionId),
            child: data.childById(log.childId),
            onApprove: () => onApproveMission(log),
            onReject: () => onRejectMission(log),
          ),
          const SizedBox(height: ZeniSpacing.md),
        ],
        for (final request in data.pendingRequests) ...[
          Text(
            '${data.childById(request.childId)?.name ?? 'Criança'} pediu um mimo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ZeniSpacing.xs),
          RewardRequestCard(
            key: Key('parent-pending-reward-${request.id}'),
            request: request,
            reward: data.rewardById(request.rewardId),
            child: data.childById(request.childId),
            onApprove: () => onApproveRewardRequest(request),
            onReject: () => onRejectRewardRequest(request),
          ),
          const SizedBox(height: ZeniSpacing.md),
        ],
      ],
    );
  }
}

class _ClearLocalDeviceDataSheet extends StatefulWidget {
  const _ClearLocalDeviceDataSheet({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_ClearLocalDeviceDataSheet> createState() =>
      _ClearLocalDeviceDataSheetState();
}

class _ClearLocalDeviceDataSheetState
    extends State<_ClearLocalDeviceDataSheet> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isClearing = false;
  String? _errorText;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmationValid = _confirmController.text.trim() == 'APAGAR';

    return ZeniModalSheetContainer(
      title: 'Apagar dados deste aparelho',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Apagar dados deste aparelho remove crianças, missões, mimos, histórico e saldo salvos localmente. Os dados da nuvem não serão apagados.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.md),
          Text(
            'Digite APAGAR para confirmar. Esta ação reinicia o app neste aparelho.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniTextInput(
            key: const Key('clear-local-data-confirm-input'),
            controller: _confirmController,
            label: 'Confirmação',
            hint: 'Digite APAGAR',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              } else {
                setState(() {});
              }
            },
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
          ZeniSecondaryButton(
            label: 'Cancelar',
            onPressed: _isClearing
                ? null
                : () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: ZeniSpacing.sm),
          ZeniPrimaryButton(
            label: _isClearing ? 'Apagando...' : 'Apagar dados deste aparelho',
            onPressed: (_isClearing || !isConfirmationValid) ? null : _confirm,
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    if (_confirmController.text.trim() != 'APAGAR') {
      setState(() {
        _errorText = 'Digite APAGAR para confirmar.';
      });
      return;
    }

    setState(() {
      _isClearing = true;
      _errorText = null;
    });

    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isClearing = false;
        _errorText =
            'Não foi possível apagar os dados deste aparelho agora. Tente novamente.';
      });
    }
  }
}

class _ManageAccountAndDataSheet extends StatelessWidget {
  const _ManageAccountAndDataSheet({required this.onClearLocalDeviceData});

  final Future<void> Function() onClearLocalDeviceData;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: 'Gerenciar dados e conta',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revise o que acontece com os dados deste aparelho e com a sua conta.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniOptionRow(
              title: 'Apagar dados deste aparelho',
              subtitle:
                  'Apaga crianças, missões, mimos, histórico e saldo salvos localmente. Os dados da nuvem não serão apagados.',
              leading: Icon(
                Icons.delete_forever_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              trailing: Text(
                'Apagar',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: onClearLocalDeviceData,
            ),
            const SizedBox(height: ZeniSpacing.sm),
            ZeniOptionRow(
              title: 'Excluir conta e dados da nuvem',
              subtitle:
                  'Indisponível nesta versão. A exclusão completa da conta e dos dados da nuvem ficará para uma etapa própria.',
              leading: Icon(
                Icons.cloud_off_rounded,
                color: ZeniColors.mutedText,
              ),
              trailing: Text(
                'Indisponível',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: ZeniColors.mutedText),
              ),
              enabled: false,
            ),
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              'Sair da conta remove apenas a sessão. Apagar dados deste aparelho remove apenas o que está salvo localmente. Nada daqui apaga automaticamente os dados da nuvem.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
        ),
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
  int get pendingCount => awaitingLogs.length + pendingRequests.length;

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

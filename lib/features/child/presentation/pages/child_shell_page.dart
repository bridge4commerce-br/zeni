import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/feedback/zeni_haptics.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/providers/zeni_repository_providers.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_confirm_action_sheet.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/layout/zeni_bottom_nav_bar.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../../core/widgets/zeni_flying_star_overlay.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../balance/presentation/widgets/history_entry_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/presentation/avatar_catalog.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../sync/presentation/providers/opportunistic_sync_providers.dart';
import '../../../sync/presentation/providers/cloud_sync_providers.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/domain/mission_undo_policy.dart';
import '../../../tts/domain/zeni_speech_text_builders.dart';
import '../../../tts/presentation/providers/zeni_tts_service.dart';
import '../../../tasks/presentation/widgets/task_completion_sheet.dart';
import '../widgets/child_home_tab.dart';
import '../widgets/child_missions_tab.dart';
import '../widgets/child_rewards_tab.dart';

class ChildShellPage extends ConsumerStatefulWidget {
  const ChildShellPage({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ChildShellPage> createState() => _ChildShellPageState();
}

class _ChildShellPageState extends ConsumerState<ChildShellPage> {
  int _currentIndex = 0;
  bool _isMascotCelebrating = false;
  Timer? _mascotCelebrationTimer;
  final _balancePillKey = GlobalKey();
  final Map<String, GlobalKey> _missionAnchorKeys = <String, GlobalKey>{};

  ZeniAppState? get _currentAppState =>
      ref.read(zeniAppStateControllerProvider).asData?.value;

  @override
  void dispose() {
    _mascotCelebrationTimer?.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime value, DateTime other) {
    return value.year == other.year &&
        value.month == other.month &&
        value.day == other.day;
  }

  Future<void> _listenToMission(Mission mission) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    ref.read(zeniHapticsProvider).selection();
    final result = await ref
        .read(zeniTtsServiceProvider)
        .speakTextForChild(
          child: data.child,
          text: ZeniMissionSpeechTextBuilder.buildMissionShortSpeech(mission),
        );
    if (!mounted || result.didSpeak) return;

    ZeniInfoPopup.show(
      context,
      title: 'Leitura em voz alta',
      message: result.message ?? 'Não foi possível reproduzir o áudio agora.',
    );
  }

  Future<void> _listenToReward(Reward reward) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    ref.read(zeniHapticsProvider).selection();
    final result = await ref
        .read(zeniTtsServiceProvider)
        .speakTextForChild(
          child: data.child,
          text: ZeniRewardSpeechTextBuilder.buildRewardShortSpeech(reward),
        );
    if (!mounted || result.didSpeak) return;

    ZeniInfoPopup.show(
      context,
      title: 'Leitura em voz alta',
      message: result.message ?? 'Não foi possível reproduzir o áudio agora.',
    );
  }

  Future<void> _listenToMissionDetails(Mission mission, MissionLog? log) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    ref.read(zeniHapticsProvider).selection();
    final result = await ref
        .read(zeniTtsServiceProvider)
        .speakTextForChild(
          child: data.child,
          text: ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
            mission: mission,
            log: log,
          ),
        );
    if (!mounted || result.didSpeak) return;

    ZeniInfoPopup.show(
      context,
      title: 'Leitura em voz alta',
      message: result.message ?? 'Não foi possível reproduzir o áudio agora.',
    );
  }

  Future<void> _listenToRewardDetails(
    Reward reward,
    RewardRequest? request,
  ) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    ref.read(zeniHapticsProvider).selection();
    final result = await ref
        .read(zeniTtsServiceProvider)
        .speakTextForChild(
          child: data.child,
          text: ZeniRewardSpeechTextBuilder.buildRewardDetailsSpeech(
            reward: reward,
            childBalance: data.child.starBalance,
            request: request,
          ),
        );
    if (!mounted || result.didSpeak) return;

    ZeniInfoPopup.show(
      context,
      title: 'Leitura em voz alta',
      message: result.message ?? 'Não foi possível reproduzir o áudio agora.',
    );
  }

  GlobalKey _missionAnchorKeyFor(String missionId) {
    return _missionAnchorKeys.putIfAbsent(missionId, GlobalKey.new);
  }

  _ChildModeData? _buildChildModeData(ZeniAppState appState) {
    final now = DateTime.now();
    final child = appState.childById(widget.childId);
    if (child == null) {
      _debugLog(
        'Child not found for childId=${widget.childId}. '
        'availableChildren=${appState.children.map((item) => item.id).join(',')}',
      );
      return null;
    }

    final missions = childMissionsForDate(
      missions: appState.missions,
      childId: child.id,
      date: now,
    );
    final logs = appState.missionLogs
        .where(
          (log) =>
              log.childId == child.id && _isSameDay(log.scheduledDate, now),
        )
        .toList();
    final rewards =
        appState.rewards
            .where(
              (reward) =>
                  reward.isActive &&
                  (reward.childId == null || reward.childId == child.id),
            )
            .toList()
          ..sort((a, b) => a.cost.compareTo(b.cost));
    final ledger =
        appState.starLedgerEntries
            .where((entry) => entry.childId == child.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pendingRewardRequests =
        appState.rewardRequests
            .where(
              (request) => request.childId == child.id && request.isPending,
            )
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    _debugLog(
      'Resolved child=${child.id} missions=${missions.length} rewards=${rewards.length} '
      'logsToday=${logs.length} pendingRewards=${pendingRewardRequests.length}',
    );
    if (missions.isEmpty || rewards.isEmpty) {
      _debugLog(
        'Visible lists detail for child=${child.id}: '
        'allMissionChildIds=${appState.missions.map((item) => item.childId).join(',')}; '
        'allRewardChildIds=${appState.rewards.map((item) => item.childId ?? 'global').join(',')}',
      );
    }

    return _ChildModeData(
      child: child,
      missions: missions,
      todayLogs: logs,
      rewards: rewards,
      pendingRewardRequests: pendingRewardRequests,
      ledgerEntries: ledger,
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ChildShell] $message');
  }

  Future<void> _completeMission(
    Mission mission,
    MissionLog? currentLog,
    GlobalKey? sourceKey,
  ) async {
    final result = await showTaskCompletionModal(
      context: context,
      mission: mission,
    );

    if (result == null) return;
    if (!mounted) return;

    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    await ref
        .read(missionRepositoryProvider)
        .submitMission(
          childId: data.child.id,
          mission: mission,
          currentLog: currentLog,
          note: result.note,
        );
    if (!mounted) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'child_submit_mission');

    final shouldAwardNow =
        mission.approvalMode == MissionApprovalMode.automatic;

    if (shouldAwardNow) {
      ref.read(zeniHapticsProvider).celebrate();
      _showMascotCelebration();
      _animateEarnedStar(sourceKey);
      ZeniSuccessPopup.show(
        context,
        title: 'Missão concluída!',
        message: 'Você ganhou ${mission.stars} estrelas.',
      );
    } else {
      ref.read(zeniHapticsProvider).confirm();
      ZeniInfoPopup.show(
        context,
        title: 'Missão enviada!',
        message: 'O responsável precisa aprovar para liberar as estrelas.',
      );
    }
  }

  void _showMascotCelebration() {
    _mascotCelebrationTimer?.cancel();
    setState(() => _isMascotCelebrating = true);
    _mascotCelebrationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isMascotCelebrating = false);
    });
  }

  void _animateEarnedStar(GlobalKey? sourceKey) {
    if (!mounted) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    final screenSize = mediaQuery?.size ?? const Size(390, 844);
    final from =
        _centerFor(sourceKey) ??
        Offset(screenSize.width * 0.48, screenSize.height * 0.56);
    final to =
        _centerFor(_balancePillKey) ??
        Offset(screenSize.width - 56, mediaQuery?.padding.top ?? 44);

    notifyDebugFlyingStarShown(from, to);
    try {
      ZeniFlyingStarOverlay.show(context: context, from: from, to: to);
    } catch (_) {
      // Ignore visual animation failures so mission completion keeps working.
    }
  }

  Offset? _centerFor(GlobalKey? key) {
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached || !renderBox.hasSize) {
      return null;
    }

    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft + renderBox.size.center(Offset.zero);
  }

  void _cancelMissionSubmission(Mission mission, MissionLog? currentLog) {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null || currentLog == null) return;

    if (currentLog.status != MissionLogStatus.awaitingApproval) return;

    ref
        .read(missionRepositoryProvider)
        .cancelMissionSubmission(missionId: mission.id, childId: data.child.id);
    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'child_cancel_mission_submission');
    ref.read(zeniHapticsProvider).cancel();

    ZeniSuccessPopup.show(
      context,
      title: 'Envio cancelado',
      message: '${mission.title} voltou para suas missões pendentes.',
    );
  }

  Future<void> _refreshPrimaryLists() async {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      final result = await ref
          .read(zeniCloudSyncControllerProvider)
          .syncNowManually();
      if (!mounted || result.isSuccess || result.message == null) {
        return;
      }

      ZeniInfoPopup.show(
        context,
        title: 'Sincronização',
        message: result.message!,
      );
      return;
    }

    ref.invalidate(zeniAppStateControllerProvider);
    await ref.read(zeniAppStateControllerProvider.future);
  }

  Future<void> _redeemReward(Reward reward) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    if (data.child.starBalance < reward.cost) {
      ref.read(zeniHapticsProvider).warn();
      ZeniInfoPopup.show(
        context,
        title: 'Continue conquistando!',
        message: 'Complete mais missões para juntar estrelas suficientes.',
      );
      return;
    }

    await ref
        .read(rewardRepositoryProvider)
        .requestReward(childId: data.child.id, reward: reward);
    if (!mounted) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'child_request_reward');
    ref.read(zeniHapticsProvider).confirm();

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo solicitado!',
      message: '${reward.cost} estrelas foram reservadas para esse mimo.',
    );
  }

  Future<void> _undoMissionCompletion(Mission mission, MissionLog log) async {
    if (!canUndoAutomaticMissionCompletion(mission: mission, log: log)) {
      return;
    }

    final shouldUndo =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return const Padding(
              padding: EdgeInsets.zero,
              child: ZeniConfirmActionSheet(
                title: 'Desfazer esta missão?',
                message:
                    'As estrelas ganhas nesta conclusão serão removidas do saldo.',
                confirmLabel: 'Desfazer conclusão',
              ),
            );
          },
        ) ??
        false;
    if (!shouldUndo || !mounted) return;

    await ref.read(missionRepositoryProvider).undoMissionCompletion(log.id);
    if (!mounted) return;

    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'child_undo_auto_mission');
    ref.read(zeniHapticsProvider).cancel();
    ZeniInfoPopup.show(
      context,
      title: 'Conclusão desfeita',
      message: '${mission.title} voltou para as missões pendentes.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(zeniAppStateControllerProvider);

    return appState.when(
      loading: () =>
          const ZeniScaffold(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const ZeniScaffold(
        child: Center(child: Text('Não foi possível carregar o perfil.')),
      ),
      data: (appData) {
        final data = _buildChildModeData(appData);

        if (data == null) {
          return const ZeniScaffold(
            appBar: ZeniTopBar(
              title: 'Perfil não encontrado',
              subtitle: 'Tente escolher outro perfil',
            ),
            child: Center(child: Text('Não encontramos essa criança.')),
          );
        }
        final canUseReadAloud = ref
            .watch(zeniTtsServiceProvider)
            .isEnabledForChild(data.child);

        final pages = [
          ChildHomeTab(
            child: data.child,
            missions: data.missions,
            todayLogs: data.todayLogs,
            rewards: data.rewards,
            pendingRewardRequests: data.pendingRewardRequests,
            logForMission: data.logForMission,
            missionAnchorKeyFor: _missionAnchorKeyFor,
            onCompleteMission: _completeMission,
            onCancelMissionSubmission: _cancelMissionSubmission,
            onUndoMissionCompletion: _undoMissionCompletion,
            onListenToMission: _listenToMission,
            onListenToMissionDetails: _listenToMissionDetails,
            canListenToMission: canUseReadAloud,
            isCelebrating: _isMascotCelebrating,
            onOpenRewards: () {
              ref.read(zeniHapticsProvider).selection();
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          ChildMissionsTab(
            missions: data.missions,
            logForMission: data.logForMission,
            missionAnchorKeyFor: _missionAnchorKeyFor,
            onCompleteMission: _completeMission,
            onCancelMissionSubmission: _cancelMissionSubmission,
            onUndoMissionCompletion: _undoMissionCompletion,
            onListenToMission: _listenToMission,
            onListenToMissionDetails: _listenToMissionDetails,
            canListenToMission: canUseReadAloud,
            onRefresh: _refreshPrimaryLists,
          ),
          ChildRewardsTab(
            childBalance: data.child.starBalance,
            rewards: data.rewards,
            pendingRewardRequests: data.pendingRewardRequests,
            rewardById: data.rewardById,
            onRedeemReward: _redeemReward,
            onListenToReward: _listenToReward,
            onListenToRewardDetails: _listenToRewardDetails,
            canListenToReward: canUseReadAloud,
            onRefresh: _refreshPrimaryLists,
          ),
          _ChildBalancePage(data: data),
        ];

        return ZeniScaffold(
          appBar: _ChildIdentityHeader(
            child: data.child,
            balancePillKey: _balancePillKey,
            onSwitchProfile: () {
              ref.read(zeniHapticsProvider).selection();
              context.go('/');
            },
          ),
          bottomNavigationBar: ZeniBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              ref.read(zeniHapticsProvider).selection();
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              ZeniBottomNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Hoje',
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
                icon: Icons.stars_outlined,
                selectedIcon: Icons.stars_rounded,
                label: 'Saldo',
              ),
            ],
          ),
          child: IndexedStack(index: _currentIndex, children: pages),
        );
      },
    );
  }
}

@visibleForTesting
List<Mission> childMissionsForDate({
  required Iterable<Mission> missions,
  required String childId,
  DateTime? date,
}) {
  final targetDate = date ?? DateTime.now();

  return missions
      .where(
        (mission) =>
            mission.childId == childId &&
            mission.isActive &&
            mission.occursOnDate(targetDate),
      )
      .toList();
}

class _ChildBalancePage extends StatelessWidget {
  const _ChildBalancePage({required this.data});

  final _ChildModeData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meu saldo', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Acompanhe as estrelas que você ganhou e usou.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          ZeniCard(
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 42)),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo atual',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ZeniSpacing.xs),
                      Text(
                        '${data.child.starBalance} estrelas',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Text('Histórico', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          for (final entry in data.ledgerEntries) ...[
            HistoryEntryCard(entry: entry),
            const SizedBox(height: ZeniSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ChildIdentityHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _ChildIdentityHeader({
    required this.child,
    required this.balancePillKey,
    required this.onSwitchProfile,
  });

  final ChildProfile child;
  final GlobalKey balancePillKey;
  final VoidCallback onSwitchProfile;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final avatar = ZeniChildAvatarCatalog.byId(child.avatarId);
    final windowClass = ZeniResponsive.windowClass(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = math.max(
      0,
      viewportWidth - (ZeniResponsive.horizontalPadding(context) * 2),
    );
    final frameWidth = math.min(
      availableWidth,
      ZeniResponsive.mainMaxWidth(context),
    );
    final frameInset = (viewportWidth - frameWidth) / 2;
    final avatarSize = switch (windowClass) {
      ZeniWindowClass.compact => 42.0,
      ZeniWindowClass.medium => 46.0,
      ZeniWindowClass.expanded => 52.0,
      ZeniWindowClass.large => 56.0,
    };
    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: frameInset,
      actionsPadding: EdgeInsets.only(
        right: math.max(0, frameInset - ZeniSpacing.md),
      ),
      title: Row(
        children: [
          Container(
            key: const Key('child-shell-avatar'),
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: ZeniColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(avatar.assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          Expanded(
            child: Text(
              child.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: windowClass == ZeniWindowClass.compact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Trocar perfil',
          icon: const Icon(Icons.swap_horiz_rounded),
          onPressed: onSwitchProfile,
        ),
        Padding(
          padding: const EdgeInsets.only(right: ZeniSpacing.md),
          child: KeyedSubtree(
            key: balancePillKey,
            child: ZeniBalancePill(stars: child.starBalance),
          ),
        ),
      ],
    );
  }
}

class _ChildModeData {
  const _ChildModeData({
    required this.child,
    required this.missions,
    required this.todayLogs,
    required this.rewards,
    required this.pendingRewardRequests,
    required this.ledgerEntries,
  });

  final ChildProfile child;
  final List<Mission> missions;
  final List<MissionLog> todayLogs;
  final List<Reward> rewards;
  final List<RewardRequest> pendingRewardRequests;
  final List<StarLedgerEntry> ledgerEntries;

  MissionLog? logForMission(String missionId) {
    for (final log in todayLogs) {
      if (log.missionId == missionId) return log;
    }

    return null;
  }

  Reward? rewardById(String rewardId) {
    for (final reward in rewards) {
      if (reward.id == rewardId) return reward;
    }

    return null;
  }

  _ChildModeData copyWith({
    ChildProfile? child,
    List<Mission>? missions,
    List<MissionLog>? todayLogs,
    List<Reward>? rewards,
    List<RewardRequest>? pendingRewardRequests,
    List<StarLedgerEntry>? ledgerEntries,
  }) {
    return _ChildModeData(
      child: child ?? this.child,
      missions: missions ?? this.missions,
      todayLogs: todayLogs ?? this.todayLogs,
      rewards: rewards ?? this.rewards,
      pendingRewardRequests:
          pendingRewardRequests ?? this.pendingRewardRequests,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
    );
  }
}

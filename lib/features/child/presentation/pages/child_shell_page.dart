import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/providers/zeni_repository_providers.dart';
import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/layout/zeni_bottom_nav_bar.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../../core/widgets/zeni_flying_star_overlay.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../balance/presentation/widgets/history_entry_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
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
  final _balancePillKey = GlobalKey();
  final Map<String, GlobalKey> _missionAnchorKeys = <String, GlobalKey>{};

  ZeniAppState? get _currentAppState =>
      ref.read(zeniAppStateControllerProvider).asData?.value;

  bool _isSameDay(DateTime value, DateTime other) {
    return value.year == other.year &&
        value.month == other.month &&
        value.day == other.day;
  }

  GlobalKey _missionAnchorKeyFor(String missionId) {
    return _missionAnchorKeys.putIfAbsent(missionId, GlobalKey.new);
  }

  _ChildModeData? _buildChildModeData(ZeniAppState appState) {
    final now = DateTime.now();
    final child = appState.childById(widget.childId);
    if (child == null) {
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

    return _ChildModeData(
      child: child,
      missions: missions,
      todayLogs: logs,
      rewards: rewards,
      pendingRewardRequests: pendingRewardRequests,
      ledgerEntries: ledger,
    );
  }

  Future<void> _completeMission(
    Mission mission,
    MissionLog? currentLog,
    GlobalKey? sourceKey,
  ) async {
    final result = await showModalBottomSheet<TaskCompletionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: TaskCompletionSheet(mission: mission),
        );
      },
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

    final shouldAwardNow =
        mission.approvalMode == MissionApprovalMode.automatic;

    if (shouldAwardNow) {
      _animateEarnedStar(sourceKey);
      ZeniSuccessPopup.show(
        context,
        title: 'Missão concluída!',
        message: 'Você ganhou ${mission.stars} estrelas.',
      );
    } else {
      ZeniInfoPopup.show(
        context,
        title: 'Missão enviada!',
        message: 'O responsável precisa aprovar para liberar as estrelas.',
      );
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        ZeniFlyingStarOverlay.show(context: context, from: from, to: to);
      } catch (_) {
        // Ignore visual animation failures so mission completion keeps working.
      }
    });
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

    ZeniSuccessPopup.show(
      context,
      title: 'Envio cancelado',
      message: '${mission.title} voltou para suas missões pendentes.',
    );
  }

  Future<void> _redeemReward(Reward reward) async {
    final appState = _currentAppState;
    if (appState == null) return;
    final data = _buildChildModeData(appState);
    if (data == null) return;

    if (data.child.starBalance < reward.cost) {
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

    ZeniSuccessPopup.show(
      context,
      title: 'Mimo solicitado!',
      message: '${reward.cost} estrelas foram reservadas para esse mimo.',
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
            onOpenRewards: () {
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
          ),
          ChildRewardsTab(
            childBalance: data.child.starBalance,
            rewards: data.rewards,
            pendingRewardRequests: data.pendingRewardRequests,
            rewardById: data.rewardById,
            onRedeemReward: _redeemReward,
          ),
          _ChildBalancePage(data: data),
        ];

        return ZeniScaffold(
          appBar: ZeniTopBar(
            title: 'Olá, ${data.child.name}!',
            subtitle: 'Vamos conquistar estrelas hoje?',
            actions: [
              IconButton(
                tooltip: 'Trocar perfil',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  context.go('/');
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: ZeniSpacing.md),
                child: KeyedSubtree(
                  key: _balancePillKey,
                  child: ZeniBalancePill(stars: data.child.starBalance),
                ),
              ),
            ],
          ),
          bottomNavigationBar: ZeniBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
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

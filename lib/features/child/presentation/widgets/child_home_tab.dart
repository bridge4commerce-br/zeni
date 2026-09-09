import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_radius.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/zeni_mascot.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/domain/mission_undo_policy.dart';
import '../../../tasks/presentation/widgets/task_child_detail_sheet.dart';
import 'child_birthday_card.dart';

/// Orders pending missions using the device's local time. `anytime` is kept
/// immediately after the current period because it is available all day.
List<Mission> orderChildHomePendingMissions({
  required List<Mission> missions,
  required DateTime localNow,
}) {
  final currentGroup = switch (localNow.hour) {
    < 12 => MissionTimeGroup.morning,
    < 18 => MissionTimeGroup.afternoon,
    _ => MissionTimeGroup.evening,
  };
  final groupOrder = <MissionTimeGroup>[
    MissionTimeGroup.morning,
    MissionTimeGroup.afternoon,
    MissionTimeGroup.evening,
  ];
  final currentIndex = groupOrder.indexOf(currentGroup);

  int priority(Mission mission) {
    if (mission.timeGroup == currentGroup) return 0;
    if (mission.timeGroup == MissionTimeGroup.anytime) return 1;
    final missionIndex = groupOrder.indexOf(mission.timeGroup);
    return missionIndex < currentIndex ? 2 : 3;
  }

  final indexedMissions = missions.asMap().entries.toList()
    ..sort((a, b) {
      final result = priority(a.value).compareTo(priority(b.value));
      return result != 0 ? result : a.key.compareTo(b.key);
    });
  return indexedMissions.map((entry) => entry.value).toList();
}

class ChildHomeTab extends StatelessWidget {
  const ChildHomeTab({
    super.key,
    required this.child,
    required this.missions,
    required this.todayLogs,
    required this.rewards,
    required this.pendingRewardRequests,
    required this.logForMission,
    required this.missionAnchorKeyFor,
    required this.onCompleteMission,
    required this.onCancelMissionSubmission,
    required this.onUndoMissionCompletion,
    required this.onListenToMission,
    required this.onListenToMissionDetails,
    required this.canListenToMission,
    required this.onOpenRewards,
    this.isCelebrating = false,
  });

  final ChildProfile child;
  final List<Mission> missions;
  final List<MissionLog> todayLogs;
  final List<Reward> rewards;
  final List<RewardRequest> pendingRewardRequests;
  final MissionLog? Function(String missionId) logForMission;
  final GlobalKey Function(String missionId) missionAnchorKeyFor;
  final void Function(Mission, MissionLog?, GlobalKey?) onCompleteMission;
  final void Function(Mission, MissionLog?) onCancelMissionSubmission;
  final void Function(Mission) onListenToMission;
  final void Function(Mission, MissionLog?) onListenToMissionDetails;
  final void Function(Mission, MissionLog) onUndoMissionCompletion;
  final VoidCallback onOpenRewards;
  final bool canListenToMission;
  final bool isCelebrating;

  @override
  Widget build(BuildContext context) {
    final metrics = _ChildHomeMetrics.forWindow(
      ZeniResponsive.windowClass(context),
    );
    final approved = todayLogs.where((log) => log.isApproved).length;
    final awaiting = todayLogs.where((log) => log.isAwaitingApproval).length;
    final pending = missions
        .where(
          (mission) =>
              (logForMission(mission.id)?.status ?? MissionLogStatus.pending) ==
              MissionLogStatus.pending,
        )
        .toList();
    final orderedPending = orderChildHomePendingMissions(
      missions: pending,
      localNow: DateTime.now(),
    );
    final awaitingMissions = missions
        .where(
          (mission) => logForMission(mission.id)?.isAwaitingApproval ?? false,
        )
        .toList();
    final currentMission = orderedPending.isEmpty ? null : orderedPending.first;
    final reward = _rewardTarget(rewards, child.starBalance);
    final mascotState = _mascotState(
      hasPendingMission: currentMission != null,
      awaitingApproval: awaiting > 0,
      allCompleted: missions.isNotEmpty && approved == missions.length,
      reward: reward,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, metrics.topSpacing, 0, 48),
      child: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChildHomeHeader(name: child.name, metrics: metrics),
            SizedBox(height: metrics.greetingSpacing),
            _SummaryArea(
              metrics: metrics,
              companion: _ZeniCompanion(
                state: mascotState,
                message: _mascotMessage(mascotState, orderedPending.length),
                metrics: metrics,
              ),
              progress: missions.isNotEmpty
                  ? _ChildDayProgress(
                      completed: approved,
                      awaitingApproval: awaiting,
                      total: missions.length,
                      metrics: metrics,
                    )
                  : null,
            ),
            SizedBox(height: metrics.sectionSpacing),
            if (_isBirthday(child)) ...[
              ChildBirthdayCard(child: child),
              const SizedBox(height: ZeniSpacing.xl),
            ],
            if (pendingRewardRequests.isNotEmpty) ...[
              _ChildPendingRewardHint(
                count: pendingRewardRequests.length,
                onTap: onOpenRewards,
              ),
              const SizedBox(height: ZeniSpacing.lg),
            ],
            if (currentMission != null) ...[
              Text('Agora', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: ZeniSpacing.sm),
              KeyedSubtree(
                key: missionAnchorKeyFor('home:${currentMission.id}'),
                child: _ChildCurrentMissionCard(
                  mission: currentMission,
                  onOpen: () => _openMissionDetails(context, currentMission),
                  metrics: metrics,
                ),
              ),
              if (orderedPending.length > 1) ...[
                const SizedBox(height: ZeniSpacing.xl),
                _ChildUpcomingMissions(
                  missions: orderedPending.skip(1).take(3).toList(),
                  onOpen: (mission) => _openMissionDetails(context, mission),
                  metrics: metrics,
                ),
              ],
            ],
            if (awaitingMissions.isNotEmpty) ...[
              const SizedBox(height: ZeniSpacing.xl),
              _AwaitingApprovalMissions(
                missions: awaitingMissions,
                onOpen: (mission) => _openMissionDetails(context, mission),
                metrics: metrics,
              ),
            ] else if (currentMission == null && missions.isEmpty) ...[
              const _ChildStatusCard(
                icon: Icons.wb_sunny_rounded,
                title: 'Sem missões por enquanto',
                message: 'Aproveite seu dia no seu ritmo.',
              ),
            ] else if (currentMission == null &&
                approved == missions.length) ...[
              const _ChildStatusCard(
                icon: Icons.check_circle_rounded,
                title: 'Tudo pronto por hoje!',
                message: 'Você cuidou muito bem das suas missões.',
              ),
            ],
            if (reward != null) ...[
              const SizedBox(height: ZeniSpacing.xl),
              _ChildRewardProgress(
                reward: reward,
                balance: child.starBalance,
                onTap: onOpenRewards,
              ),
            ],
          ],
        ),
      ),
    );
  }

  ZeniMascotState _mascotState({
    required bool hasPendingMission,
    required bool awaitingApproval,
    required bool allCompleted,
    required Reward? reward,
  }) {
    if (isCelebrating) return ZeniMascotState.celebrating;
    if (awaitingApproval) return ZeniMascotState.waitingApproval;
    if (allCompleted) return ZeniMascotState.achievement;
    if (reward != null &&
        reward.cost - child.starBalance > 0 &&
        reward.cost - child.starBalance <= 10) {
      return ZeniMascotState.rewardClose;
    }
    if (hasPendingMission) return ZeniMascotState.encourage;
    return ZeniMascotState.sleeping;
  }

  String _mascotMessage(ZeniMascotState state, int pendingMissions) =>
      switch (state) {
        ZeniMascotState.celebrating => 'Mandou muito bem! ✨',
        ZeniMascotState.waitingApproval => 'Agora é só esperar o responsável.',
        ZeniMascotState.achievement => 'Seu dia está completo! 🎉',
        ZeniMascotState.rewardClose => 'Está pertinho do seu mimo! 🎁',
        ZeniMascotState.encourage when pendingMissions == 1 =>
          'Falta só essa! 💚',
        ZeniMascotState.encourage => 'Vamos nessa! ⭐',
        ZeniMascotState.sleeping => 'Hoje está tranquilo por aqui.',
        _ => 'Vamos ver o seu dia?',
      };

  Reward? _rewardTarget(List<Reward> rewards, int balance) {
    final sorted = [...rewards]..sort((a, b) => a.cost.compareTo(b.cost));
    for (final reward in sorted) {
      if (reward.cost >= balance) return reward;
    }
    return sorted.isEmpty ? null : sorted.first;
  }

  bool _isBirthday(ChildProfile profile) {
    final birthDate = profile.birthDate;
    if (birthDate == null) return false;
    final today = DateTime.now();
    return today.day == birthDate.day && today.month == birthDate.month;
  }

  Future<void> _openMissionDetails(
    BuildContext context,
    Mission mission,
  ) async {
    final log = logForMission(mission.id);
    final action = await showTaskChildDetailModal(
      context: context,
      mission: mission,
      onListenToMission: () => onListenToMission(mission),
      onListenToMissionDetails: () =>
          onListenToMissionDetails(mission, logForMission(mission.id)),
      log: log,
      showListenActions: canListenToMission,
      canUndoCompletion: canUndoAutomaticMissionCompletion(
        mission: mission,
        log: log,
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case TaskChildDetailAction.complete:
        onCompleteMission(
          mission,
          logForMission(mission.id),
          missionAnchorKeyFor('home:${mission.id}'),
        );
      case TaskChildDetailAction.cancelSubmission:
        onCancelMissionSubmission(mission, logForMission(mission.id));
      case TaskChildDetailAction.undoCompletion:
        final approvedLog = logForMission(mission.id);
        if (approvedLog != null) onUndoMissionCompletion(mission, approvedLog);
      case null:
        break;
    }
  }
}

class _ChildHomeHeader extends StatelessWidget {
  const _ChildHomeHeader({required this.name, required this.metrics});
  final String name;
  final _ChildHomeMetrics metrics;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oi, $name! 👋',
              style: metrics.isTablet
                  ? Theme.of(context).textTheme.headlineLarge
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'Vamos cuidar do seu dia?',
              style:
                  (metrics.isTablet
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.bodyLarge)
                      ?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SummaryArea extends StatelessWidget {
  const _SummaryArea({
    required this.metrics,
    required this.companion,
    required this.progress,
  });

  final _ChildHomeMetrics metrics;
  final Widget companion;
  final Widget? progress;

  @override
  Widget build(BuildContext context) {
    if (progress == null) return companion;
    if (!metrics.usesSummaryRow) {
      return Column(
        children: [
          companion,
          const SizedBox(height: ZeniSpacing.xxl),
          progress!,
        ],
      );
    }

    return Row(
      key: const Key('child-home-summary-row'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: companion),
        SizedBox(width: metrics.summaryGap),
        Expanded(flex: 5, child: progress!),
      ],
    );
  }
}

class _ChildHomeMetrics {
  const _ChildHomeMetrics({
    required this.windowClass,
    required this.topSpacing,
    required this.greetingSpacing,
    required this.sectionSpacing,
    required this.companionHorizontalPadding,
    required this.companionVerticalPadding,
    required this.companionGap,
    required this.mascotSize,
    required this.missionCardPadding,
    required this.missionIconSize,
    required this.missionEmojiSize,
    required this.upcomingHorizontalPadding,
    required this.upcomingVerticalPadding,
    required this.upcomingEmojiSize,
    required this.awaitingCardPadding,
    required this.progressHeight,
    required this.summaryGap,
  });

  factory _ChildHomeMetrics.forWindow(ZeniWindowClass windowClass) =>
      switch (windowClass) {
        ZeniWindowClass.compact => const _ChildHomeMetrics(
          windowClass: ZeniWindowClass.compact,
          topSpacing: 16,
          greetingSpacing: ZeniSpacing.lg,
          sectionSpacing: ZeniSpacing.xl,
          companionHorizontalPadding: ZeniSpacing.lg,
          companionVerticalPadding: ZeniSpacing.md,
          companionGap: ZeniSpacing.md,
          mascotSize: 92,
          missionCardPadding: ZeniSpacing.lg,
          missionIconSize: 48,
          missionEmojiSize: 27,
          upcomingHorizontalPadding: ZeniSpacing.md,
          upcomingVerticalPadding: ZeniSpacing.xs,
          upcomingEmojiSize: 25,
          awaitingCardPadding: ZeniSpacing.md,
          progressHeight: 12,
          summaryGap: 0,
        ),
        ZeniWindowClass.medium => const _ChildHomeMetrics(
          windowClass: ZeniWindowClass.medium,
          topSpacing: ZeniSpacing.xl,
          greetingSpacing: ZeniSpacing.xl,
          sectionSpacing: ZeniSpacing.xxl,
          companionHorizontalPadding: ZeniSpacing.xl,
          companionVerticalPadding: ZeniSpacing.xl,
          companionGap: ZeniSpacing.lg,
          mascotSize: 120,
          missionCardPadding: ZeniSpacing.xl,
          missionIconSize: 60,
          missionEmojiSize: 30,
          upcomingHorizontalPadding: ZeniSpacing.lg,
          upcomingVerticalPadding: ZeniSpacing.sm,
          upcomingEmojiSize: 28,
          awaitingCardPadding: ZeniSpacing.lg,
          progressHeight: 12,
          summaryGap: ZeniSpacing.lg,
        ),
        ZeniWindowClass.expanded => const _ChildHomeMetrics(
          windowClass: ZeniWindowClass.expanded,
          topSpacing: ZeniSpacing.xxl,
          greetingSpacing: ZeniSpacing.xxl,
          sectionSpacing: 40,
          companionHorizontalPadding: ZeniSpacing.xxl,
          companionVerticalPadding: ZeniSpacing.xxl,
          companionGap: ZeniSpacing.xl,
          mascotSize: 148,
          missionCardPadding: ZeniSpacing.xxl,
          missionIconSize: 68,
          missionEmojiSize: 34,
          upcomingHorizontalPadding: ZeniSpacing.xl,
          upcomingVerticalPadding: ZeniSpacing.md,
          upcomingEmojiSize: 30,
          awaitingCardPadding: ZeniSpacing.xl,
          progressHeight: 14,
          summaryGap: ZeniSpacing.xl,
        ),
        ZeniWindowClass.large => const _ChildHomeMetrics(
          windowClass: ZeniWindowClass.large,
          topSpacing: 40,
          greetingSpacing: 40,
          sectionSpacing: 48,
          companionHorizontalPadding: 40,
          companionVerticalPadding: 40,
          companionGap: ZeniSpacing.xxl,
          mascotSize: 160,
          missionCardPadding: 40,
          missionIconSize: 72,
          missionEmojiSize: 36,
          upcomingHorizontalPadding: ZeniSpacing.xxl,
          upcomingVerticalPadding: ZeniSpacing.md,
          upcomingEmojiSize: 32,
          awaitingCardPadding: ZeniSpacing.xxl,
          progressHeight: 14,
          summaryGap: 40,
        ),
      };

  final ZeniWindowClass windowClass;
  final double topSpacing;
  final double greetingSpacing;
  final double sectionSpacing;
  final double companionHorizontalPadding;
  final double companionVerticalPadding;
  final double companionGap;
  final double mascotSize;
  final double missionCardPadding;
  final double missionIconSize;
  final double missionEmojiSize;
  final double upcomingHorizontalPadding;
  final double upcomingVerticalPadding;
  final double upcomingEmojiSize;
  final double awaitingCardPadding;
  final double progressHeight;
  final double summaryGap;

  bool get isTablet => windowClass != ZeniWindowClass.compact;
  bool get usesSummaryRow =>
      windowClass == ZeniWindowClass.expanded ||
      windowClass == ZeniWindowClass.large;
}

class _ZeniCompanion extends StatelessWidget {
  const _ZeniCompanion({
    required this.state,
    required this.message,
    required this.metrics,
  });
  final ZeniMascotState state;
  final String message;
  final _ChildHomeMetrics metrics;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Zeni diz: $message',
    child: ExcludeSemantics(
      child: Container(
        key: const Key('child-home-companion'),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: metrics.companionHorizontalPadding,
          vertical: metrics.companionVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: ZeniColors.primaryLight.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(ZeniRadius.xl),
        ),
        child: Row(
          children: [
            ZeniMascot(state: state, size: metrics.mascotSize),
            SizedBox(width: metrics.companionGap),
            Expanded(
              child: Text(
                message,
                style: metrics.isTablet
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChildDayProgress extends StatelessWidget {
  const _ChildDayProgress({
    required this.completed,
    required this.awaitingApproval,
    required this.total,
    required this.metrics,
  });
  final int completed;
  final int awaitingApproval;
  final int total;
  final _ChildHomeMetrics metrics;
  @override
  Widget build(BuildContext context) {
    final status = awaitingApproval > 0
        ? '$awaitingApproval aguardando aprovação'
        : '$completed de $total concluídas';
    return Semantics(
      label: 'Seu dia: $status',
      child: ExcludeSemantics(
        child: ZeniCard(
          key: const Key('child-home-day-progress'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu dia',
                style: metrics.isTablet
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                status,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
              const SizedBox(height: ZeniSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(ZeniRadius.pill),
                child: LinearProgressIndicator(
                  value: (completed / total).clamp(0, 1),
                  minHeight: metrics.progressHeight,
                  backgroundColor: ZeniColors.primaryLight.withValues(
                    alpha: 0.36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCurrentMissionCard extends StatelessWidget {
  const _ChildCurrentMissionCard({
    required this.mission,
    required this.onOpen,
    required this.metrics,
  });
  final Mission mission;
  final VoidCallback onOpen;
  final _ChildHomeMetrics metrics;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Missão de agora: ${mission.title}${mission.stars > 0 ? ', ${mission.stars} estrelas' : ''}',
    child: ZeniCard(
      key: const Key('child-home-current-mission'),
      onTap: onOpen,
      padding: EdgeInsets.all(metrics.missionCardPadding),
      child: Row(
        children: [
          Container(
            width: metrics.missionIconSize,
            height: metrics.missionIconSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ZeniColors.primaryLight.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Text(
              mission.emoji,
              style: TextStyle(fontSize: metrics.missionEmojiSize),
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metrics.isTablet
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'Toque para ver e concluir',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          if (mission.stars > 0)
            Text(
              '+${mission.stars} ⭐',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          const SizedBox(width: ZeniSpacing.xs),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _ChildUpcomingMissions extends StatelessWidget {
  const _ChildUpcomingMissions({
    required this.missions,
    required this.onOpen,
    required this.metrics,
  });
  final List<Mission> missions;
  final ValueChanged<Mission> onOpen;
  final _ChildHomeMetrics metrics;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Depois', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: ZeniSpacing.sm),
      ZeniCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < missions.length; i++) ...[
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: metrics.upcomingHorizontalPadding,
                    vertical: metrics.upcomingVerticalPadding,
                  ),
                  leading: Text(
                    missions[i].emoji,
                    style: TextStyle(fontSize: metrics.upcomingEmojiSize),
                  ),
                  title: Text(
                    missions[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    missions[i].stars > 0 ? '+${missions[i].stars} ⭐' : '›',
                  ),
                  onTap: () => onOpen(missions[i]),
                ),
              ),
              if (i != missions.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    ],
  );
}

class _AwaitingApprovalMissions extends StatelessWidget {
  const _AwaitingApprovalMissions({
    required this.missions,
    required this.onOpen,
    required this.metrics,
  });
  final List<Mission> missions;
  final ValueChanged<Mission> onOpen;
  final _ChildHomeMetrics metrics;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Aguardando aprovação',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: ZeniSpacing.sm),
      for (final mission in missions) ...[
        ZeniCard(
          onTap: () => onOpen(mission),
          padding: EdgeInsets.all(metrics.awaitingCardPadding),
          child: Row(
            children: [
              Text(
                mission.emoji,
                style: TextStyle(fontSize: metrics.upcomingEmojiSize),
              ),
              const SizedBox(width: ZeniSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Aguardando o responsável',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text('+${mission.stars} ⭐'),
            ],
          ),
        ),
        const SizedBox(height: ZeniSpacing.sm),
      ],
    ],
  );
}

class _ChildRewardProgress extends StatelessWidget {
  const _ChildRewardProgress({
    required this.reward,
    required this.balance,
    required this.onTap,
  });
  final Reward reward;
  final int balance;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final missing = (reward.cost - balance).clamp(0, reward.cost);
    return ZeniCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso para mimo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  missing == 0
                      ? '${reward.title} já está disponível!'
                      : 'Faltam $missing estrelas para ${reward.title}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
                const SizedBox(height: ZeniSpacing.sm),
                LinearProgressIndicator(
                  value: reward.cost == 0
                      ? 1
                      : (balance / reward.cost).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(ZeniRadius.pill),
                  color: ZeniColors.purple,
                  backgroundColor: ZeniColors.purple.withValues(alpha: 0.14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildStatusCard extends StatelessWidget {
  const _ChildStatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => ZeniCard(
    child: Row(
      children: [
        Icon(icon, color: ZeniColors.primaryDark, size: 38),
        const SizedBox(width: ZeniSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: ZeniSpacing.xs),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChildPendingRewardHint extends StatelessWidget {
  const _ChildPendingRewardHint({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.card_giftcard_rounded),
    label: Text(
      count == 1
          ? 'Você tem mimo aguardando aprovação 🎁'
          : 'Você tem $count mimos aguardando aprovação 🎁',
    ),
  );
}

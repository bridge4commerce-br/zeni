import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_radius.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
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
    this.balanceAnchorKey,
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
  final GlobalKey? balanceAnchorKey;

  @override
  Widget build(BuildContext context) {
    final windowClass = ZeniResponsive.windowClass(context);
    final expression = ZeniVisualExpression.resolve(ZeniVisualMode.kids);
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
    final currentMission = orderedPending.firstOrNull;
    final reward = _rewardTarget(rewards, child.starBalance);
    final mascotState = _mascotState(
      hasPendingMission: currentMission != null,
      awaitingApproval: awaiting > 0,
      allCompleted: missions.isNotEmpty && approved == missions.length,
      reward: reward,
    );

    const greeting = _ChildHomeHeader();
    final balance = _ChildBalanceHighlight(
      balance: child.starBalance,
      anchorKey: balanceAnchorKey,
    );
    final companion = _ZeniCompanion(
      state: mascotState,
      message: _mascotMessage(mascotState, orderedPending.length),
    );
    final progress = missions.isEmpty
        ? null
        : _ChildDayProgress(
            completed: approved,
            awaitingApproval: awaiting,
            total: missions.length,
          );
    final current = currentMission == null
        ? null
        : KeyedSubtree(
            key: missionAnchorKeyFor('home:${currentMission.id}'),
            child: _ChildCurrentMissionCard(
              mission: currentMission,
              prominentTitle:
                  windowClass == ZeniWindowClass.expanded ||
                  windowClass == ZeniWindowClass.large,
              onOpen: () => _openMissionDetails(context, currentMission),
            ),
          );
    final later = orderedPending.length <= 1
        ? null
        : _ChildMissionList(
            title: 'Depois',
            missions: orderedPending.skip(1).take(3).toList(),
            onOpen: (mission) => _openMissionDetails(context, mission),
          );
    final waiting = awaitingMissions.isEmpty
        ? null
        : _ChildMissionList(
            key: const Key('child-home-waiting'),
            title: 'Aguardando aprovação',
            missions: awaitingMissions,
            waitingApproval: true,
            onOpen: (mission) => _openMissionDetails(context, mission),
          );
    final rewardProgress = reward == null
        ? null
        : _ChildRewardProgress(
            reward: reward,
            balance: child.starBalance,
            onTap: onOpenRewards,
          );
    final status = _statusFor(
      currentMission: currentMission,
      awaitingMissions: awaitingMissions,
      approved: approved,
    );
    final notices = <Widget>[
      if (_isBirthday(child)) ChildBirthdayCard(child: child),
      if (pendingRewardRequests.isNotEmpty)
        _ChildPendingRewardHint(
          count: pendingRewardRequests.length,
          onTap: onOpenRewards,
        ),
    ];

    final content = switch (windowClass) {
      ZeniWindowClass.compact ||
      ZeniWindowClass.medium => _ChildHomeSingleColumn(
        greeting: greeting,
        notices: notices,
        balance: balance,
        companion: companion,
        current: current,
        status: status,
        progress: progress,
        later: later,
        waiting: waiting,
        reward: rewardProgress,
        spacing: expression.sectionSpacing,
      ),
      ZeniWindowClass.expanded => _ChildHomePortraitLayout(
        greeting: greeting,
        notices: notices,
        balance: balance,
        companion: companion,
        progress: progress,
        current: current,
        status: status,
        later: later,
        waiting: waiting,
        reward: rewardProgress,
        spacing: expression.sectionSpacing,
      ),
      ZeniWindowClass.large => _ChildHomeLandscapeLayout(
        greeting: greeting,
        notices: notices,
        balance: balance,
        companion: companion,
        progress: progress,
        current: current,
        status: status,
        later: later,
        waiting: waiting,
        reward: rewardProgress,
        spacing: expression.sectionSpacing,
      ),
    };

    final topSpacing = switch (windowClass) {
      ZeniWindowClass.compact => ZeniSpacing.spaceCard,
      ZeniWindowClass.medium => ZeniSpacing.spaceGroup,
      ZeniWindowClass.expanded => ZeniSpacing.spaceSection,
      ZeniWindowClass.large => ZeniSpacing.spaceHero,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: topSpacing, bottom: ZeniSpacing.spaceHero),
      child: ZeniPageFrame(width: ZeniPageWidth.main, child: content),
    );
  }

  Widget? _statusFor({
    required Mission? currentMission,
    required List<Mission> awaitingMissions,
    required int approved,
  }) {
    if (currentMission != null || awaitingMissions.isNotEmpty) return null;
    if (missions.isEmpty) {
      return const _ChildStatus(
        key: Key('child-home-empty-state'),
        icon: Icons.wb_sunny_rounded,
        title: 'Sem missões por enquanto',
        message: 'Aproveite seu dia no seu ritmo.',
      );
    }
    if (approved == missions.length) {
      return const _ChildStatus(
        icon: Icons.check_circle_rounded,
        title: 'Tudo pronto por hoje!',
        message: 'Você cuidou muito bem das suas missões.',
      );
    }
    return null;
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
    return sorted.firstOrNull;
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

class _ChildHomeSingleColumn extends StatelessWidget {
  const _ChildHomeSingleColumn({
    required this.greeting,
    required this.notices,
    required this.balance,
    required this.companion,
    required this.current,
    required this.status,
    required this.progress,
    required this.later,
    required this.waiting,
    required this.reward,
    required this.spacing,
  });

  final Widget greeting;
  final List<Widget> notices;
  final Widget balance;
  final Widget companion;
  final Widget? current;
  final Widget? status;
  final Widget? progress;
  final Widget? later;
  final Widget? waiting;
  final Widget? reward;
  final double spacing;

  @override
  Widget build(BuildContext context) => _ChildHomeFlow(
    key: const Key('child-home-compact-layout'),
    spacing: spacing,
    children: [
      greeting,
      if (notices.isNotEmpty)
        _ChildHomeFlow(spacing: ZeniSpacing.spaceControl, children: notices),
      balance,
      companion,
      ?current,
      ?status,
      ?progress,
      ?later,
      ?waiting,
      ?reward,
    ],
  );
}

class _ChildHomePortraitLayout extends StatelessWidget {
  const _ChildHomePortraitLayout({
    required this.greeting,
    required this.notices,
    required this.balance,
    required this.companion,
    required this.progress,
    required this.current,
    required this.status,
    required this.later,
    required this.waiting,
    required this.reward,
    required this.spacing,
  });

  final Widget greeting;
  final List<Widget> notices;
  final Widget balance;
  final Widget companion;
  final Widget? progress;
  final Widget? current;
  final Widget? status;
  final Widget? later;
  final Widget? waiting;
  final Widget? reward;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final secondary = <Widget>[?waiting, ?reward];
    final lowerContent = _balancedColumns(
      key: const Key('child-home-portrait-lower-row'),
      left: later,
      right: secondary.isEmpty
          ? null
          : _ChildHomeFlow(spacing: spacing, children: secondary),
      spacing: ZeniSpacing.spaceGroup,
      leftFlex: 3,
      rightFlex: 2,
    );

    return _ChildHomeFlow(
      key: const Key('child-home-portrait-layout'),
      spacing: spacing,
      children: [
        greeting,
        if (notices.isNotEmpty)
          _ChildHomeFlow(spacing: ZeniSpacing.spaceControl, children: notices),
        balance,
        if (progress == null)
          companion
        else
          Row(
            key: const Key('child-home-summary-row'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: companion),
              const SizedBox(width: ZeniSpacing.spaceGroup),
              Expanded(flex: 2, child: progress!),
            ],
          ),
        ?current,
        ?status,
        ?lowerContent,
      ],
    );
  }
}

class _ChildHomeLandscapeLayout extends StatelessWidget {
  const _ChildHomeLandscapeLayout({
    required this.greeting,
    required this.notices,
    required this.balance,
    required this.companion,
    required this.progress,
    required this.current,
    required this.status,
    required this.later,
    required this.waiting,
    required this.reward,
    required this.spacing,
  });

  final Widget greeting;
  final List<Widget> notices;
  final Widget balance;
  final Widget companion;
  final Widget? progress;
  final Widget? current;
  final Widget? status;
  final Widget? later;
  final Widget? waiting;
  final Widget? reward;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final primary = _ChildHomeFlow(
      key: const Key('child-home-primary-column'),
      spacing: spacing,
      children: [companion, ?current, ?status, ?later],
    );
    final secondaryItems = <Widget>[?progress, ?waiting, ?reward];
    final body = secondaryItems.isEmpty
        ? primary
        : Row(
            key: const Key('child-home-landscape-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: primary),
              const SizedBox(width: ZeniSpacing.spaceSection),
              Expanded(
                flex: 4,
                child: _ChildHomeFlow(
                  key: const Key('child-home-secondary-column'),
                  spacing: spacing,
                  children: secondaryItems,
                ),
              ),
            ],
          );

    return _ChildHomeFlow(
      spacing: spacing,
      children: [
        greeting,
        if (notices.isNotEmpty)
          _ChildHomeFlow(spacing: ZeniSpacing.spaceControl, children: notices),
        balance,
        body,
      ],
    );
  }
}

Widget? _balancedColumns({
  required Key key,
  required Widget? left,
  required Widget? right,
  required double spacing,
  required int leftFlex,
  required int rightFlex,
}) {
  if (left == null) return right;
  if (right == null) return left;
  return Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: leftFlex, child: left),
      SizedBox(width: spacing),
      Expanded(flex: rightFlex, child: right),
    ],
  );
}

class _ChildHomeFlow extends StatelessWidget {
  const _ChildHomeFlow({
    super.key,
    required this.children,
    required this.spacing,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(height: spacing),
        children[index],
      ],
    ],
  );
}

class _ChildHomeHeader extends StatelessWidget {
  const _ChildHomeHeader();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final windowClass = ZeniResponsive.windowClass(context);
    final greetingStyle = windowClass == ZeniWindowClass.compact
        ? typography.sectionTitle
        : typography.pageTitle;

    return Text('Vamos cuidar do seu dia? 👋', style: greetingStyle);
  }
}

class _ChildBalanceHighlight extends StatelessWidget {
  const _ChildBalanceHighlight({required this.balance, this.anchorKey});

  final int balance;
  final GlobalKey? anchorKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    final balanceText = balance == 1 ? '1 estrela' : '$balance estrelas';
    final background = Color.alphaBlend(
      colors.accentStar.withValues(alpha: .16),
      colors.surface,
    );

    return Semantics(
      container: true,
      label: 'Seu saldo: $balanceText',
      child: ExcludeSemantics(
        child: ZeniSurface(
          key: const Key('child-home-balance'),
          role: ZeniSurfaceRole.highlight,
          mode: ZeniVisualMode.kids,
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.spaceGroup,
            vertical: ZeniSpacing.spaceCard,
          ),
          child: Row(
            children: [
              KeyedSubtree(
                key: anchorKey,
                child: Container(
                  width: ZeniTouchTargets.childPriority,
                  height: ZeniTouchTargets.childPriority,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentStar.withValues(alpha: .28),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: ZeniSpacing.spaceCard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seu saldo', style: typography.metadata),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(balanceText, style: typography.sectionTitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZeniCompanion extends StatelessWidget {
  const _ZeniCompanion({required this.state, required this.message});

  final ZeniMascotState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Semantics(
      container: true,
      label: 'Zeni diz: $message',
      child: ExcludeSemantics(
        child: ZeniSurface(
          key: const Key('child-home-companion'),
          role: ZeniSurfaceRole.grouped,
          mode: ZeniVisualMode.kids,
          backgroundColor: colors.surfaceSubtle,
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.spaceGroup,
            vertical: ZeniSpacing.spaceCard,
          ),
          child: Row(
            children: [
              ZeniMascot(state: state, size: 96),
              const SizedBox(width: ZeniSpacing.spaceCard),
              Expanded(child: Text(message, style: typography.cardTitle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildDayProgress extends StatelessWidget {
  const _ChildDayProgress({
    required this.completed,
    required this.awaitingApproval,
    required this.total,
  });

  final int completed;
  final int awaitingApproval;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    final status = awaitingApproval > 0
        ? '$awaitingApproval aguardando aprovação'
        : '$completed de $total concluídas';
    return Semantics(
      label: 'Seu dia: $status',
      child: ExcludeSemantics(
        child: ZeniSurface(
          key: const Key('child-home-day-progress'),
          role: ZeniSurfaceRole.grouped,
          mode: ZeniVisualMode.kids,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seu dia', style: typography.cardTitle),
              const SizedBox(height: ZeniSpacing.spaceInline),
              Text(status, style: typography.metadata),
              const SizedBox(height: ZeniSpacing.spaceCard),
              ClipRRect(
                borderRadius: BorderRadius.circular(ZeniRadius.pill),
                child: LinearProgressIndicator(
                  value: (completed / total).clamp(0, 1),
                  minHeight: 10,
                  color: colors.brand,
                  backgroundColor: colors.surfaceSubtle,
                ),
              ),
              const SizedBox(height: ZeniSpacing.spaceCard),
              Wrap(
                spacing: ZeniSpacing.spaceCard,
                runSpacing: ZeniSpacing.spaceInline,
                children: [
                  _ProgressLabel(
                    icon: Icons.check_circle_outline_rounded,
                    label: '$completed concluídas',
                  ),
                  if (awaitingApproval > 0)
                    _ProgressLabel(
                      icon: Icons.hourglass_top_rounded,
                      label: '$awaitingApproval em análise',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: ZeniSpacing.spaceInlineTight),
        Text(label, style: typography.metadata),
      ],
    );
  }
}

class _ChildCurrentMissionCard extends StatelessWidget {
  const _ChildCurrentMissionCard({
    required this.mission,
    required this.prominentTitle,
    required this.onOpen,
  });

  final Mission mission;
  final bool prominentTitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Semantics(
      container: true,
      label:
          'Missão de agora: ${mission.title}${mission.stars > 0 ? ', ${mission.stars} estrelas' : ''}',
      child: ZeniSurface(
        key: const Key('child-home-current-mission'),
        role: ZeniSurfaceRole.highlight,
        mode: ZeniVisualMode.kids,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agora', style: typography.sectionTitle),
            const SizedBox(height: ZeniSpacing.spaceCard),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ZeniTouchTargets.childPriority,
                  height: ZeniTouchTargets.childPriority,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    mission.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: ZeniSpacing.spaceCard),
                Expanded(
                  child: Text(
                    mission.title,
                    style: prominentTitle
                        ? typography.sectionTitle
                        : typography.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.spaceCard),
            Wrap(
              spacing: ZeniSpacing.spaceCard,
              runSpacing: ZeniSpacing.spaceInline,
              children: [
                _MissionMetadata(
                  icon: Icons.schedule_rounded,
                  label: mission.timeGroup.label,
                ),
                if (mission.stars > 0)
                  _MissionMetadata(
                    icon: Icons.star_rounded,
                    label: '+${mission.stars} estrelas',
                    color: colors.actionPrimary,
                  ),
                if (mission.approvalMode == MissionApprovalMode.parentApproval)
                  const _MissionMetadata(
                    icon: Icons.verified_user_outlined,
                    label: 'O responsável confere depois',
                  ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            ZeniButton(
              label: 'Ver missão',
              icon: Icons.arrow_forward_rounded,
              role: ZeniButtonRole.primary,
              mode: ZeniVisualMode.kids,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionMetadata extends StatelessWidget {
  const _MissionMetadata({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final effectiveColor = color ?? context.zeniColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: ZeniSpacing.spaceInlineTight),
        Text(label, style: typography.metadata.copyWith(color: effectiveColor)),
      ],
    );
  }
}

class _ChildMissionList extends StatelessWidget {
  const _ChildMissionList({
    super.key,
    required this.title,
    required this.missions,
    required this.onOpen,
    this.waitingApproval = false,
  });

  final String title;
  final List<Mission> missions;
  final ValueChanged<Mission> onOpen;
  final bool waitingApproval;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceControl),
        ZeniSurface(
          role: ZeniSurfaceRole.grouped,
          mode: ZeniVisualMode.kids,
          backgroundColor: waitingApproval ? colors.surfaceSubtle : null,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < missions.length; index++) ...[
                _ChildMissionRow(
                  mission: missions[index],
                  waitingApproval: waitingApproval,
                  onTap: () => onOpen(missions[index]),
                ),
                if (index != missions.length - 1)
                  Divider(height: 1, color: colors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildMissionRow extends StatelessWidget {
  const _ChildMissionRow({
    required this.mission,
    required this.waitingApproval,
    required this.onTap,
  });

  final Mission mission;
  final bool waitingApproval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final stateLabel = waitingApproval
        ? 'Aguardando o responsável'
        : mission.timeGroup.label;
    return Semantics(
      button: true,
      label:
          '${mission.title}, $stateLabel${mission.stars > 0 ? ', ${mission.stars} estrelas' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ZeniTouchTargets.childPriority,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZeniSpacing.spaceCard,
                  vertical: ZeniSpacing.spaceControl,
                ),
                child: Row(
                  children: [
                    Text(mission.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: ZeniSpacing.spaceControl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mission.title, style: typography.bodyEmphasis),
                          const SizedBox(height: ZeniSpacing.spaceInlineTight),
                          Row(
                            children: [
                              if (waitingApproval) ...[
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(
                                  width: ZeniSpacing.spaceInlineTight,
                                ),
                              ],
                              Flexible(
                                child: Text(
                                  stateLabel,
                                  style: typography.metadata,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ZeniSpacing.spaceInline),
                    if (mission.stars > 0)
                      Text('+${mission.stars} ⭐', style: typography.metadata),
                    const SizedBox(width: ZeniSpacing.spaceInlineTight),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mimo no horizonte', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceControl),
        ZeniSurface(
          key: const Key('child-home-reward-progress'),
          role: ZeniSurfaceRole.interactive,
          mode: ZeniVisualMode.kids,
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: ZeniSpacing.spaceControl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title, style: typography.cardTitle),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      missing == 0
                          ? 'Já está disponível!'
                          : 'Faltam $missing estrelas para chegar lá.',
                      style: typography.metadata,
                    ),
                    const SizedBox(height: ZeniSpacing.spaceControl),
                    LinearProgressIndicator(
                      value: reward.cost == 0
                          ? 1
                          : (balance / reward.cost).clamp(0, 1),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(ZeniRadius.pill),
                      color: colors.brand,
                      backgroundColor: colors.surfaceSubtle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ZeniSpacing.spaceInline),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildStatus extends StatelessWidget {
  const _ChildStatus({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return ZeniSurface(
      role: ZeniSurfaceRole.plain,
      mode: ZeniVisualMode.kids,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ZeniSpacing.spaceCard),
        child: Row(
          children: [
            Container(
              width: ZeniTouchTargets.childPriority,
              height: ZeniTouchTargets.childPriority,
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: colors.actionPrimary, size: 30),
            ),
            const SizedBox(width: ZeniSpacing.spaceCard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: typography.cardTitle),
                  const SizedBox(height: ZeniSpacing.spaceInlineTight),
                  Text(message, style: typography.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildPendingRewardHint extends StatelessWidget {
  const _ChildPendingRewardHint({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final typography = ZeniTypography.of(context);
    final message = count == 1
        ? 'Você tem mimo aguardando aprovação 🎁'
        : 'Você tem $count mimos aguardando aprovação 🎁';
    return ZeniSurface(
      role: ZeniSurfaceRole.interactive,
      mode: ZeniVisualMode.kids,
      backgroundColor: colors.surfaceSubtle,
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: colors.actionPrimary),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(child: Text(message, style: typography.bodyEmphasis)),
          const SizedBox(width: ZeniSpacing.spaceInline),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }
}

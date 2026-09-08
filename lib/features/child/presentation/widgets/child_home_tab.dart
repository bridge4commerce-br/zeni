import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_radius.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
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
    final approved = todayLogs.where((log) => log.isApproved).length;
    final awaiting = todayLogs.where((log) => log.isAwaitingApproval).length;
    final pending = missions
        .where(
          (mission) =>
              (logForMission(mission.id)?.status ?? MissionLogStatus.pending) ==
              MissionLogStatus.pending,
        )
        .toList();
    final currentMission = pending.isEmpty ? null : pending.first;
    final reward = _rewardTarget(rewards, child.starBalance);
    final mascotState = _mascotState(
      hasPendingMission: currentMission != null,
      awaitingApproval: awaiting > 0,
      allCompleted: missions.isNotEmpty && approved == missions.length,
      reward: reward,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChildHomeHeader(name: child.name),
          const SizedBox(height: ZeniSpacing.lg),
          _ZeniCompanion(
            state: mascotState,
            message: _mascotMessage(mascotState, currentMission != null),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          if (_isBirthday(child)) ...[
            ChildBirthdayCard(child: child),
            const SizedBox(height: ZeniSpacing.xl),
          ],
          if (missions.isNotEmpty) ...[
            _ChildDayProgress(
              completed: approved,
              awaitingApproval: awaiting,
              total: missions.length,
            ),
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
            Text(
              'Missão de agora',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.sm),
            KeyedSubtree(
              key: missionAnchorKeyFor('home:${currentMission.id}'),
              child: _ChildCurrentMissionCard(
                mission: currentMission,
                onOpen: () => _openMissionDetails(context, currentMission),
              ),
            ),
            if (pending.length > 1) ...[
              const SizedBox(height: ZeniSpacing.xl),
              _ChildUpcomingMissions(
                missions: pending.skip(1).take(3).toList(),
                onOpen: (mission) => _openMissionDetails(context, mission),
              ),
            ],
          ] else if (awaiting > 0) ...[
            _ChildStatusCard(
              icon: Icons.hourglass_top_rounded,
              title: awaiting == 1
                  ? 'Missão aguardando aprovação'
                  : '$awaiting missões aguardando aprovação',
              message: 'O responsável vai revisar em breve.',
            ),
          ] else if (missions.isEmpty) ...[
            const _ChildStatusCard(
              icon: Icons.wb_sunny_rounded,
              title: 'Sem missões por enquanto',
              message: 'Aproveite seu dia no seu ritmo.',
            ),
          ] else if (approved == missions.length) ...[
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

  String _mascotMessage(ZeniMascotState state, bool hasPendingMission) =>
      switch (state) {
        ZeniMascotState.celebrating => 'Mandou muito bem! ✨',
        ZeniMascotState.waitingApproval => 'Agora é só esperar o responsável.',
        ZeniMascotState.achievement => 'Seu dia está completo! 🎉',
        ZeniMascotState.rewardClose => 'Está pertinho do seu mimo! 🎁',
        ZeniMascotState.encourage when hasPendingMission => 'Falta só essa! 💚',
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
    final action = await showModalBottomSheet<TaskChildDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TaskChildDetailSheet(
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
        ),
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
  const _ChildHomeHeader({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oi, $name! 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'Vamos cuidar do seu dia?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
        ),
      ),
      const ZeniBrandLogo(width: 64),
    ],
  );
}

class _ZeniCompanion extends StatelessWidget {
  const _ZeniCompanion({required this.state, required this.message});
  final ZeniMascotState state;
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Zeni diz: $message',
    child: ExcludeSemantics(
      child: Container(
        key: const Key('child-home-companion'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: ZeniSpacing.lg,
          vertical: ZeniSpacing.md,
        ),
        decoration: BoxDecoration(
          color: ZeniColors.primaryLight.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(ZeniRadius.xl),
        ),
        child: Row(
          children: [
            ZeniMascot(state: state, size: 92),
            const SizedBox(width: ZeniSpacing.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
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
  });
  final int completed;
  final int awaitingApproval;
  final int total;
  @override
  Widget build(BuildContext context) {
    final status = awaitingApproval > 0
        ? '$awaitingApproval aguardando aprovação'
        : '$completed de $total concluídas';
    return Semantics(
      label: 'Seu dia: $status',
      child: ExcludeSemantics(
        child: ZeniCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seu dia', style: Theme.of(context).textTheme.titleLarge),
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
                  minHeight: 12,
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
  const _ChildCurrentMissionCard({required this.mission, required this.onOpen});
  final Mission mission;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Missão de agora: ${mission.title}${mission.stars > 0 ? ', ${mission.stars} estrelas' : ''}',
    child: ZeniCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZeniColors.primaryLight.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  mission.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const Spacer(),
              if (mission.stars > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZeniSpacing.md,
                    vertical: ZeniSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: ZeniColors.accent.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(ZeniRadius.pill),
                  ),
                  child: Text(
                    '+${mission.stars} ⭐',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          Text(
            mission.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Toque para ver e concluir.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Ver missão'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChildUpcomingMissions extends StatelessWidget {
  const _ChildUpcomingMissions({required this.missions, required this.onOpen});
  final List<Mission> missions;
  final ValueChanged<Mission> onOpen;
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ZeniSpacing.lg,
                    vertical: ZeniSpacing.xs,
                  ),
                  leading: Text(
                    missions[i].emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                  title: Text(
                    missions[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: missions[i].stars > 0
                      ? Text('+${missions[i].stars} ⭐')
                      : null,
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

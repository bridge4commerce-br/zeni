import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../tasks/data/models/mission.dart';

class ParentChildManagementSheet extends StatelessWidget {
  const ParentChildManagementSheet({
    super.key,
    required this.child,
    required this.missions,
    required this.rewards,
    required this.ledgerEntries,
    required this.onEditProfile,
    required this.onArchiveProfile,
  });

  final ChildProfile child;
  final List<Mission> missions;
  final List<Reward> rewards;
  final List<StarLedgerEntry> ledgerEntries;
  final VoidCallback onEditProfile;
  final VoidCallback onArchiveProfile;

  @override
  Widget build(BuildContext context) {
    final childMissions = missions
        .where((mission) => mission.childId == child.id)
        .toList();

    final availableRewards = rewards
        .where((reward) => reward.childId == null || reward.childId == child.id)
        .toList();

    final childLedger =
        ledgerEntries.where((entry) => entry.childId == child.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ZeniModalSheetContainer(
      title: 'Gerenciar criança',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniCard(
              child: Row(
                children: [
                  ZeniAvatar(label: child.name, emoji: child.emoji, size: 72),
                  const SizedBox(width: ZeniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: ZeniSpacing.xs),
                        Text(
                          '${child.streakCount} dias de sequência',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ZeniColors.mutedText),
                        ),
                        if (child.birthDate != null) ...[
                          const SizedBox(height: ZeniSpacing.xs),
                          Text(
                            'Aniversário: ${_formatDate(child.birthDate!)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ZeniColors.mutedText),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ZeniBalancePill(stars: child.starBalance),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar perfil'),
                onPressed: onEditProfile,
              ),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ChildSummaryMetricCard(
                    emoji: '✅',
                    value: '${childMissions.length}',
                    label: 'missões',
                  ),
                ),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: _ChildSummaryMetricCard(
                    emoji: '🎁',
                    value: '${availableRewards.length}',
                    label: 'mimos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZeniSpacing.xl),
            Text(
              'Missões da criança',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            if (childMissions.isEmpty)
              const _EmptyChildSectionCard(
                emoji: '✨',
                title: 'Nenhuma missão ainda',
                message: 'Crie missões para acompanhar a rotina da criança.',
              )
            else
              for (final mission in childMissions.take(4)) ...[
                _ChildMissionMiniCard(mission: mission),
                const SizedBox(height: ZeniSpacing.sm),
              ],
            const SizedBox(height: ZeniSpacing.xl),
            Text(
              'Mimos disponíveis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            if (availableRewards.isEmpty)
              const _EmptyChildSectionCard(
                emoji: '🎁',
                title: 'Nenhum mimo ainda',
                message: 'Cadastre recompensas para motivar a criança.',
              )
            else
              for (final reward in availableRewards.take(4)) ...[
                _ChildRewardMiniCard(reward: reward),
                const SizedBox(height: ZeniSpacing.sm),
              ],
            const SizedBox(height: ZeniSpacing.xl),
            Text(
              'Histórico recente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            if (childLedger.isEmpty)
              const _EmptyChildSectionCard(
                emoji: '⭐',
                title: 'Sem histórico ainda',
                message: 'As movimentações de estrelas aparecerão aqui.',
              )
            else
              for (final entry in childLedger.take(4)) ...[
                _ChildLedgerMiniCard(entry: entry),
                const SizedBox(height: ZeniSpacing.sm),
              ],
            const SizedBox(height: ZeniSpacing.xl),
            const Divider(),
            const SizedBox(height: ZeniSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.archive_rounded),
                label: const Text('Arquivar criança'),
                onPressed: onArchiveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
  }
}

class _ChildSummaryMetricCard extends StatelessWidget {
  const _ChildSummaryMetricCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: ZeniSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ZeniSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ChildMissionMiniCard extends StatelessWidget {
  const _ChildMissionMiniCard({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(mission.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${mission.timeGroup.label} · ${mission.stars} estrelas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: mission.status.label,
            icon: Icons.check_circle_rounded,
            tone: StatusBadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _ChildRewardMiniCard extends StatelessWidget {
  const _ChildRewardMiniCard({required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${reward.cost} estrelas · ${reward.renewal.label}',
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
}

class _ChildLedgerMiniCard extends StatelessWidget {
  const _ChildLedgerMiniCard({required this.entry});

  final StarLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPositive = entry.amount >= 0;

    return ZeniCard(
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
            color: isPositive ? ZeniColors.success : ZeniColors.error,
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  entry.description ?? 'Movimentação de estrelas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Text(
            '${isPositive ? '+' : ''}${entry.amount} ⭐',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isPositive ? ZeniColors.success : ZeniColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChildSectionCard extends StatelessWidget {
  const _EmptyChildSectionCard({
    required this.emoji,
    required this.title,
    required this.message,
  });

  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
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
}

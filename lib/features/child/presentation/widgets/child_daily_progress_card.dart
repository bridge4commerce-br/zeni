import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';

class ChildDailyProgressCard extends StatelessWidget {
  const ChildDailyProgressCard({
    super.key,
    required this.completed,
    required this.awaitingApproval,
    required this.total,
  });

  final int completed;
  final int awaitingApproval;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total == 0 ? 1 : total;
    final progress = completed / safeTotal;
    final remaining = total - completed - awaitingApproval;

    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seu dia hoje', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            '$completed de $total missões concluídas',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 12,
              backgroundColor: ZeniColors.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: ZeniSpacing.md),
          Text(
            _statusText(remaining),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
      ),
    );
  }

  String _statusText(int remaining) {
    if (total == 0) return 'Nenhuma missão para hoje.';
    if (remaining <= 0 && awaitingApproval == 0) return 'Tudo pronto por hoje!';
    if (awaitingApproval > 0 && remaining <= 0) {
      return 'Agora é só esperar o responsável aprovar.';
    }
    if (awaitingApproval > 0) {
      return '$awaitingApproval aguardando aprovação e $remaining para fazer.';
    }

    return 'Faltam $remaining missões para completar o dia.';
  }
}

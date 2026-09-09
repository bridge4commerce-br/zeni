import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../balance/domain/monthly_star_projection.dart';
import '../../../family/data/models/child_profile.dart';

class MonthlyStarProjectionCard extends StatelessWidget {
  const MonthlyStarProjectionCard({
    super.key,
    required this.child,
    required this.projection,
    this.childSelector,
  });

  final ChildProfile child;
  final MonthlyStarProjectionResult projection;
  final Widget? childSelector;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (childSelector != null) ...[
            childSelector!,
            const SizedBox(height: ZeniSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Potencial do mês', style: textTheme.titleLarge),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      '${child.name} ainda pode ganhar até ${projection.maxPossibleStars} estrelas neste mês.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              ZeniBalancePill(stars: projection.currentBalance),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          _ProjectionMetaRow(
            label: 'Dias restantes',
            value: '${projection.daysRemainingInMonth}',
          ),
          const SizedBox(height: ZeniSpacing.sm),
          _ProjectionMetaRow(
            label: 'Missões previstas',
            value: '${projection.totalRemainingOccurrences}',
          ),
          const SizedBox(height: ZeniSpacing.sm),
          _ProjectionMetaRow(
            label: 'Estrelas possíveis',
            value: '${projection.maxPossibleStars}',
          ),
        ],
      ),
    );
  }
}

class _ProjectionMetaRow extends StatelessWidget {
  const _ProjectionMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

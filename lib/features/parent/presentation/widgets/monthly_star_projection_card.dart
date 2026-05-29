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
  });

  final ChildProfile child;
  final MonthlyStarProjectionResult projection;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projeção do mês', style: textTheme.titleLarge),
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
            label: 'Ocorrências possíveis',
            value: '${projection.totalRemainingOccurrences}',
          ),
          const SizedBox(height: ZeniSpacing.lg),
          for (final scenario in projection.scenarios) ...[
            _ProjectionScenarioRow(result: scenario),
            if (scenario != projection.scenarios.last)
              const SizedBox(height: ZeniSpacing.sm),
          ],
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

class _ProjectionScenarioRow extends StatelessWidget {
  const _ProjectionScenarioRow({required this.result});

  final MonthlyProjectionScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final tone = switch (result.scenario) {
      MonthlyProjectionScenario.conservative => ZeniColors.warning,
      MonthlyProjectionScenario.realistic => ZeniColors.primaryDark,
      MonthlyProjectionScenario.maximum => ZeniColors.info,
    };

    return Container(
      padding: const EdgeInsets.all(ZeniSpacing.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.scenario.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '+${result.projectedEarnedStars} estrelas',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tone),
                ),
              ],
            ),
          ),
          Text(
            '${result.projectedBalance}',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

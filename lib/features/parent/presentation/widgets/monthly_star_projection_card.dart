import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
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
    final typography = ZeniTypography.of(context);

    return ZeniSurface(
      role: ZeniSurfaceRole.highlight,
      mode: ZeniVisualMode.parent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (childSelector != null) ...[
            childSelector!,
            const SizedBox(height: ZeniSpacing.spaceCard),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Potencial do mês', style: typography.sectionTitle),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      '${child.name} ainda pode ganhar até ${projection.maxPossibleStars} estrelas neste mês.',
                      style: typography.body,
                    ),
                  ],
                ),
              ),
              ZeniBalancePill(stars: projection.currentBalance),
            ],
          ),
          const SizedBox(height: ZeniSpacing.spaceGroup),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = ZeniAdaptiveGrid.columnsForWidth(
                availableWidth: constraints.maxWidth,
                windowClass: ZeniResponsive.windowClass(context),
                minItemWidth: 132,
              );
              final itemWidth =
                  (constraints.maxWidth -
                      (columns - 1) * ZeniSpacing.spaceControl) /
                  columns;
              return Wrap(
                spacing: ZeniSpacing.spaceControl,
                runSpacing: ZeniSpacing.spaceControl,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _ProjectionMetric(
                      label: 'Dias restantes',
                      value: '${projection.daysRemainingInMonth}',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ProjectionMetric(
                      label: 'Missões previstas',
                      value: '${projection.totalRemainingOccurrences}',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ProjectionMetric(
                      label: 'Estrelas possíveis',
                      value: '${projection.maxPossibleStars}',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectionMetric extends StatelessWidget {
  const _ProjectionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.metadata),
        const SizedBox(height: ZeniSpacing.spaceInlineTight),
        Text(value, style: typography.cardTitle),
      ],
    );
  }
}

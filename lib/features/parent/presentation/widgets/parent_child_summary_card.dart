import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../family/data/models/child_profile.dart';

class ParentChildSummaryCard extends StatelessWidget {
  const ParentChildSummaryCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
  });

  final ChildProfile child;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Semantics(
      button: onTap != null,
      label:
          '${child.name}, ${child.starBalance} estrelas, ${child.streakCount} dias de sequência',
      child: Material(
        color: isSelected ? colors.surfaceSubtle : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            key: Key('parent-family-child-${child.id}'),
            padding: const EdgeInsets.symmetric(
              horizontal: ZeniSpacing.spaceCard,
              vertical: ZeniSpacing.spaceControl,
            ),
            child: Row(
              children: [
                ZeniAvatar(label: child.name, emoji: child.emoji, size: 60),
                const SizedBox(width: ZeniSpacing.spaceControl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              child.name,
                              style: typography.cardTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: ZeniSpacing.spaceInlineTight),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: colors.actionPrimary,
                              semanticLabel: 'Selecionada para projeção',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: ZeniSpacing.spaceInlineTight),
                      Text(
                        '${child.streakCount} dias de sequência',
                        style: typography.metadata,
                      ),
                    ],
                  ),
                ),
                ZeniBalancePill(stars: child.starBalance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../data/models/star_ledger_entry.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({super.key, required this.entry});

  final StarLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final amountPrefix = entry.amount > 0 ? '+' : '';
    final amountColor = entry.amount > 0
        ? colors.actionPrimary
        : entry.amount < 0
        ? Theme.of(context).colorScheme.error
        : colors.textSecondary;
    final localCreatedAt = entry.createdAt.toLocal();
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(localCreatedAt);
    final description = entry.description?.trim();
    final semanticDescription = description == null || description.isEmpty
        ? ''
        : ', $description';

    return Semantics(
      container: true,
      label:
          '$amountPrefix${entry.amount} estrelas, ${entry.title}$semanticDescription, $dateLabel',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.spaceCard,
            vertical: ZeniSpacing.spaceCard,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                entry.amount > 0
                    ? Icons.add_circle_rounded
                    : entry.amount < 0
                    ? Icons.remove_circle_rounded
                    : Icons.stars_rounded,
                color: amountColor,
                size: 30,
              ),
              const SizedBox(width: ZeniSpacing.spaceControl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: typography.cardTitle),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: ZeniSpacing.spaceInlineTight),
                      Text(description, style: typography.metadata),
                    ],
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(dateLabel, style: typography.metadata),
                  ],
                ),
              ),
              const SizedBox(width: ZeniSpacing.spaceInline),
              Text(
                '$amountPrefix${entry.amount} ⭐',
                style: typography.bodyEmphasis.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

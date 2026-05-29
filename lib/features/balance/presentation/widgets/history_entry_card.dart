import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../data/models/star_ledger_entry.dart';

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({super.key, required this.entry});

  final StarLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final amountPrefix = entry.amount > 0 ? '+' : '';
    final amountColor = entry.amount > 0
        ? ZeniColors.success
        : ZeniColors.error;

    return ZeniCard(
      child: Row(
        children: [
          Icon(
            entry.amount > 0
                ? Icons.add_circle_rounded
                : Icons.remove_circle_rounded,
            color: amountColor,
            size: 30,
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (entry.description != null) ...[
                  const SizedBox(height: ZeniSpacing.xs),
                  Text(
                    entry.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Text(
            '$amountPrefix${entry.amount} ⭐',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

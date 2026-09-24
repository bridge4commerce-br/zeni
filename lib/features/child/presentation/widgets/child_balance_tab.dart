import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../balance/presentation/widgets/history_entry_card.dart';

class ChildBalanceTab extends StatelessWidget {
  const ChildBalanceTab({
    super.key,
    required this.childBalance,
    required this.ledgerEntries,
  });

  final int childBalance;
  final List<StarLedgerEntry> ledgerEntries;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceSection,
        bottom: ZeniSpacing.spaceCanvas + MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo',
              key: const Key('child-balance-title'),
              style: typography.pageTitle,
            ),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(
              'Acompanhe as estrelas que você ganhou e usou.',
              style: typography.body,
            ),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            _BalanceHighlight(childBalance: childBalance),
            const SizedBox(height: ZeniSpacing.spaceSection),
            Text('Histórico de estrelas', style: typography.sectionTitle),
            const SizedBox(height: ZeniSpacing.spaceCard),
            if (ledgerEntries.isEmpty)
              const _EmptyBalanceHistory()
            else
              ZeniSurface(
                key: const Key('child-balance-history-list'),
                role: ZeniSurfaceRole.grouped,
                mode: ZeniVisualMode.kids,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < ledgerEntries.length;
                      index++
                    ) ...[
                      HistoryEntryCard(
                        key: Key(
                          'child-balance-entry-${ledgerEntries[index].id}',
                        ),
                        entry: ledgerEntries[index],
                      ),
                      if (index < ledgerEntries.length - 1)
                        const _BalanceHistoryDivider(),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHighlight extends StatelessWidget {
  const _BalanceHighlight({required this.childBalance});

  final int childBalance;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);

    return ZeniSurface(
      key: const Key('child-balance-highlight'),
      role: ZeniSurfaceRole.highlight,
      mode: ZeniVisualMode.kids,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo atual', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text('Estrelas disponíveis agora.', style: typography.metadata),
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.spaceControl),
          ZeniBalancePill(stars: childBalance),
        ],
      ),
    );
  }
}

class _EmptyBalanceHistory extends StatelessWidget {
  const _EmptyBalanceHistory();

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return ZeniSurface(
      key: const Key('child-balance-empty-state'),
      role: ZeniSurfaceRole.grouped,
      mode: ZeniVisualMode.kids,
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.textSecondary),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nenhuma movimentação ainda', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text(
                  'Quando estrelas entrarem ou saírem, elas aparecerão aqui.',
                  style: typography.metadata,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceHistoryDivider extends StatelessWidget {
  const _BalanceHistoryDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: ZeniSpacing.spaceCard,
    endIndent: ZeniSpacing.spaceCard,
    color: context.zeniColors.borderSubtle,
  );
}

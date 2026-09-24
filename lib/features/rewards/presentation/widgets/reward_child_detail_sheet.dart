import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/models/reward.dart';
import '../../data/models/reward_request.dart';

enum RewardChildDetailAction { redeem }

Future<RewardChildDetailAction?> showRewardChildDetailModal({
  required BuildContext context,
  required Reward reward,
  required int childBalance,
  required VoidCallback onListenToReward,
  required VoidCallback onListenToRewardDetails,
  RewardRequest? pendingRequest,
  bool showListenActions = true,
}) {
  final content = RewardChildDetailSheet(
    reward: reward,
    childBalance: childBalance,
    onListenToReward: onListenToReward,
    onListenToRewardDetails: onListenToRewardDetails,
    pendingRequest: pendingRequest,
    showListenActions: showListenActions,
  );

  if (ZeniAdaptiveModal.usesDialog(context)) {
    return showDialog<RewardChildDetailAction>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(ZeniSpacing.spaceGroup),
        child: ZeniAdaptiveModalFrame(child: content),
      ),
    );
  }

  return showModalBottomSheet<RewardChildDetailAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: content,
    ),
  );
}

class RewardChildDetailSheet extends StatelessWidget {
  const RewardChildDetailSheet({
    super.key,
    required this.reward,
    required this.childBalance,
    required this.onListenToReward,
    required this.onListenToRewardDetails,
    this.pendingRequest,
    this.showListenActions = true,
  });

  final Reward reward;
  final int childBalance;
  final VoidCallback onListenToReward;
  final VoidCallback onListenToRewardDetails;
  final RewardRequest? pendingRequest;
  final bool showListenActions;

  bool get canRedeem => childBalance >= reward.cost;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final missingStars = reward.cost - childBalance;
    final availability = canRedeem
        ? 'Você pode pedir este mimo agora.'
        : 'Faltam $missingStars estrelas para pedir.';
    final status = pendingRequest == null
        ? availability
        : 'Pedido aguardando o responsável.';

    return ZeniModalSheetContainer(
      title: 'Detalhes do mimo',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZeniSurface(
              key: const Key('child-reward-detail-summary'),
              role: ZeniSurfaceRole.highlight,
              mode: ZeniVisualMode.kids,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward.title, style: typography.cardTitle),
                        const SizedBox(height: ZeniSpacing.spaceInlineTight),
                        Text(status, style: typography.metadata),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            Text('Sobre o mimo', style: typography.sectionTitle),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(reward.description, style: typography.body),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            ZeniSurface(
              key: const Key('child-reward-detail-metadata'),
              role: ZeniSurfaceRole.grouped,
              mode: ZeniVisualMode.kids,
              child: Column(
                children: [
                  _RewardDetailRow(
                    icon: Icons.star_rounded,
                    label: 'Custa',
                    value: '${reward.cost} estrelas',
                  ),
                  const SizedBox(height: ZeniSpacing.spaceCard),
                  _RewardDetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Seu saldo',
                    value: '$childBalance estrelas',
                  ),
                  const SizedBox(height: ZeniSpacing.spaceCard),
                  _RewardDetailRow(
                    icon: canRedeem
                        ? Icons.check_circle_rounded
                        : Icons.stars_rounded,
                    label: 'Disponibilidade',
                    value: availability,
                  ),
                  if (pendingRequest != null) ...[
                    const SizedBox(height: ZeniSpacing.spaceCard),
                    const _RewardDetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Pedido',
                      value: 'Aguardando responsável',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.spaceGroup),
            if (showListenActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _RewardSpeechActionButton(
                      label: 'Mimo',
                      semanticLabel: 'Ouvir mimo',
                      onPressed: onListenToReward,
                    ),
                  ),
                  const SizedBox(width: ZeniSpacing.spaceControl),
                  Expanded(
                    child: _RewardSpeechActionButton(
                      label: 'Completo',
                      semanticLabel: 'Ouvir completo',
                      onPressed: onListenToRewardDetails,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZeniSpacing.spaceControl),
            ],
            ZeniButton(
              label: canRedeem ? 'Pedir mimo' : 'Continuar juntando estrelas',
              icon: canRedeem
                  ? Icons.card_giftcard_rounded
                  : Icons.stars_rounded,
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(canRedeem ? RewardChildDetailAction.redeem : null);
              },
              role: canRedeem
                  ? ZeniButtonRole.primary
                  : ZeniButtonRole.secondary,
              mode: ZeniVisualMode.kids,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardDetailRow extends StatelessWidget {
  const _RewardDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.actionPrimary),
        const SizedBox(width: ZeniSpacing.spaceControl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: typography.metadata),
              const SizedBox(height: ZeniSpacing.spaceInlineTight),
              Text(value, style: typography.bodyEmphasis),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewardSpeechActionButton extends StatelessWidget {
  const _RewardSpeechActionButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ZeniButton(
        label: label,
        icon: Icons.volume_up_rounded,
        onPressed: onPressed,
        role: ZeniButtonRole.secondary,
        mode: ZeniVisualMode.kids,
      ),
    );
  }
}

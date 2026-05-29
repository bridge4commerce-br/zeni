import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';

class ChildDailyMessageCard extends StatelessWidget {
  const ChildDailyMessageCard({
    super.key,
    required this.child,
    required this.totalMissions,
    required this.completedMissions,
    required this.awaitingApprovalMissions,
  });

  final ChildProfile child;
  final int totalMissions;
  final int completedMissions;
  final int awaitingApprovalMissions;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          ZeniAvatar(label: child.name, emoji: child.emoji, size: 72),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_message, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  _subtitle,
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

  String get _message {
    if (_isBirthday) {
      return 'Feliz aniversário, ${child.name}! 🎂';
    }

    if (totalMissions > 0 && completedMissions == totalMissions) {
      return 'Uau, ${child.name}! 🎉';
    }

    if (awaitingApprovalMissions > 0) {
      return 'Muito bem, ${child.name}! ✨';
    }

    return 'Olá, ${child.name}! 🌟';
  }

  String get _subtitle {
    if (_isBirthday) {
      return 'Hoje é seu dia especial. Que tal conquistar estrelas comemorando?';
    }

    if (totalMissions == 0) {
      return 'Hoje está tranquilo por aqui.';
    }

    if (completedMissions == totalMissions) {
      return 'Você terminou suas missões de hoje.';
    }

    if (awaitingApprovalMissions > 0) {
      return 'Você já enviou missão para aprovação. Continue assim!';
    }

    return 'Você tem $totalMissions missões hoje. Vamos começar?';
  }

  bool get _isBirthday {
    final birthDate = child.birthDate;
    if (birthDate == null) return false;

    final today = DateTime.now();

    return today.day == birthDate.day && today.month == birthDate.month;
  }
}

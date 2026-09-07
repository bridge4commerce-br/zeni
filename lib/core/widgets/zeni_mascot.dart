import 'package:flutter/material.dart';

import '../theme/zeni_animation.dart';

enum ZeniMascotState {
  idle,
  encourage,
  waitingApproval,
  celebrating,
  sleeping,
  thinking,
  rewardClose,
  achievement,
}

extension ZeniMascotStateX on ZeniMascotState {
  String get assetPath => switch (this) {
    ZeniMascotState.idle => 'assets/mascot/webp/zeni_mascot_idle.webp',
    ZeniMascotState.encourage =>
      'assets/mascot/webp/zeni_mascot_encourage.webp',
    ZeniMascotState.waitingApproval =>
      'assets/mascot/webp/zeni_mascot_waiting_approval.webp',
    ZeniMascotState.celebrating =>
      'assets/mascot/webp/zeni_mascot_celebrating.webp',
    ZeniMascotState.sleeping => 'assets/mascot/webp/zeni_mascot_sleeping.webp',
    ZeniMascotState.thinking => 'assets/mascot/webp/zeni_mascot_thinking.webp',
    ZeniMascotState.rewardClose =>
      'assets/mascot/webp/zeni_mascot_reward_close.webp',
    ZeniMascotState.achievement =>
      'assets/mascot/webp/zeni_mascot_achievement.webp',
  };

  String get semanticLabel => switch (this) {
    ZeniMascotState.idle => 'Zeni está aqui para ajudar',
    ZeniMascotState.encourage => 'Zeni está torcendo por você',
    ZeniMascotState.waitingApproval => 'Zeni está aguardando aprovação',
    ZeniMascotState.celebrating => 'Zeni está comemorando',
    ZeniMascotState.sleeping => 'Zeni está descansando',
    ZeniMascotState.thinking => 'Zeni está pensando',
    ZeniMascotState.rewardClose => 'Zeni está perto de um mimo',
    ZeniMascotState.achievement => 'Zeni celebra uma conquista',
  };
}

class ZeniMascot extends StatelessWidget {
  const ZeniMascot({
    super.key,
    required this.state,
    this.size = 144,
    this.semanticLabel,
  });

  final ZeniMascotState state;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel ?? state.semanticLabel,
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: ZeniAnimation.normal,
          switchInCurve: ZeniAnimation.entranceCurve,
          switchOutCurve: ZeniAnimation.exitCurve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: Image.asset(
            state.assetPath,
            key: ValueKey(state),
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

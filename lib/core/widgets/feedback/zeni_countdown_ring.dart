import 'package:flutter/material.dart';

import '../../theme/zeni_radius.dart';

class ZeniCountdownRing extends StatelessWidget {
  const ZeniCountdownRing({
    super.key,
    required this.progress,
    required this.secondsRemaining,
    required this.color,
    this.size = 36,
  });

  final double progress;
  final int secondsRemaining;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      label: '$secondsRemaining segundos restantes',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: safeProgress,
              strokeWidth: 3,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
            Container(
              width: size * 0.72,
              height: size * 0.72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(ZeniRadius.pill),
              ),
              child: Text(
                '$secondsRemaining',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

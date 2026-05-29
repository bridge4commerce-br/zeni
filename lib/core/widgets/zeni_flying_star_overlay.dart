import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/zeni_colors.dart';

@visibleForTesting
void Function(Offset from, Offset to)? debugOnFlyingStarShown;

class ZeniFlyingStarOverlay {
  const ZeniFlyingStarOverlay._();

  static Future<void> show({
    required BuildContext context,
    required Offset from,
    required Offset to,
    Duration duration = const Duration(milliseconds: 760),
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final controller = AnimationController(
      vsync: overlay,
      duration: duration,
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubicEmphasized,
    );

    try {
      debugOnFlyingStarShown?.call(from, to);
    } catch (_) {
      // Ignore testing hook failures so the visual effect never interrupts UX.
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: curved,
                builder: (context, child) {
                  final t = curved.value;
                  final x = lerpDouble(from.dx, to.dx, t) ?? to.dx;
                  final yBase = lerpDouble(from.dy, to.dy, t) ?? to.dy;
                  final arcHeight = 54 * math.sin(t * math.pi);
                  final y = yBase - arcHeight;
                  final scale = t < 0.5
                      ? lerpDouble(0.86, 1.12, t * 2) ?? 1
                      : lerpDouble(1.12, 0.82, (t - 0.5) * 2) ?? 1;
                  final opacity = t < 0.78
                      ? 1.0
                      : (1 - ((t - 0.78) / 0.22)).clamp(0.0, 1.0);

                  return Positioned(
                    left: x - 24,
                    top: y - 24,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: const _FlyingStar(),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      await controller.forward();
    } finally {
      entry.remove();
      controller.dispose();
    }
  }
}

class _FlyingStar extends StatelessWidget {
  const _FlyingStar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFFFF1AE),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ZeniColors.warning.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text('⭐', style: TextStyle(fontSize: 26)),
    );
  }
}

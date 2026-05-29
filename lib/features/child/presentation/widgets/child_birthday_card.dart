import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';

class ChildBirthdayCard extends StatefulWidget {
  const ChildBirthdayCard({super.key, required this.child});

  final ChildProfile child;

  @override
  State<ChildBirthdayCard> createState() => _ChildBirthdayCardState();
}

class _ChildBirthdayCardState extends State<ChildBirthdayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiPiece> _pieces = List<_ConfettiPiece>.generate(
    20,
    _createPiece,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playConfetti();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playConfetti() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ZeniCard(
            onTap: _playConfetti,
            child: Row(
              children: [
                ZeniAvatar(
                  label: widget.child.name,
                  emoji: widget.child.emoji,
                  size: 72,
                ),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feliz aniversário, ${widget.child.name}! 🎂',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: ZeniSpacing.xs),
                      Text(
                        'Hoje é seu dia especial.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ZeniColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _BirthdayConfettiPainter(
                      progress: _controller.value,
                      pieces: _pieces,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayConfettiPainter extends CustomPainter {
  const _BirthdayConfettiPainter({
    required this.progress,
    required this.pieces,
  });

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;

    for (final piece in pieces) {
      final paint = Paint()
        ..color = piece.color.withValues(alpha: 1 - progress);
      final x = piece.startX * size.width;
      final y = (-16 + progress * (size.height + 40)) + piece.delayOffset;
      final sway = math.sin((progress * math.pi * 2) + piece.waveOffset) * 14;
      final rotation = progress * piece.spinTurns * math.pi * 2;

      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(rotation);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        height: piece.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BirthdayConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pieces != pieces;
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.startX,
    required this.delayOffset,
    required this.width,
    required this.height,
    required this.spinTurns,
    required this.waveOffset,
    required this.color,
  });

  final double startX;
  final double delayOffset;
  final double width;
  final double height;
  final double spinTurns;
  final double waveOffset;
  final Color color;
}

_ConfettiPiece _createPiece(int index) {
  const colors = [
    Color(0xFFFF7A59),
    Color(0xFFFFC857),
    Color(0xFF50C878),
    Color(0xFF4DA8FF),
    Color(0xFFFF6FB5),
  ];

  final seeded = math.Random(index * 17 + 3);

  return _ConfettiPiece(
    startX: 0.08 + seeded.nextDouble() * 0.84,
    delayOffset: -seeded.nextDouble() * 120,
    width: 6 + seeded.nextDouble() * 6,
    height: 10 + seeded.nextDouble() * 8,
    spinTurns: 1 + seeded.nextDouble() * 2,
    waveOffset: seeded.nextDouble() * math.pi * 2,
    color: colors[index % colors.length],
  );
}

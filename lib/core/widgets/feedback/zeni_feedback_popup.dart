import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';
import '../../theme/zeni_shadows.dart';
import '../../theme/zeni_spacing.dart';
import 'zeni_countdown_ring.dart';

enum ZeniFeedbackType { success, error, info }

extension ZeniFeedbackTypeStyle on ZeniFeedbackType {
  Color get color {
    return switch (this) {
      ZeniFeedbackType.success => ZeniColors.success,
      ZeniFeedbackType.error => ZeniColors.error,
      ZeniFeedbackType.info => ZeniColors.info,
    };
  }

  IconData get icon {
    return switch (this) {
      ZeniFeedbackType.success => Icons.check_circle_rounded,
      ZeniFeedbackType.error => Icons.error_rounded,
      ZeniFeedbackType.info => Icons.info_rounded,
    };
  }

  String get semanticLabel {
    return switch (this) {
      ZeniFeedbackType.success => 'Sucesso',
      ZeniFeedbackType.error => 'Erro',
      ZeniFeedbackType.info => 'Informação',
    };
  }
}

class ZeniFeedbackPopup extends StatefulWidget {
  const ZeniFeedbackPopup({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String title;
  final String message;
  final ZeniFeedbackType type;
  final Duration duration;
  final VoidCallback onDismissed;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required ZeniFeedbackType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return Future.value();

    final completer = Completer<void>();
    late final OverlayEntry entry;
    var removed = false;

    void removeEntry() {
      if (removed) return;
      removed = true;
      entry.remove();
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (_) => ZeniFeedbackPopup(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismissed: removeEntry,
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }

  @override
  State<ZeniFeedbackPopup> createState() => _ZeniFeedbackPopupState();
}

class _ZeniFeedbackPopupState extends State<ZeniFeedbackPopup> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final nextRemaining = _remaining - const Duration(milliseconds: 100);

      if (nextRemaining <= Duration.zero) {
        widget.onDismissed();
        return;
      }

      if (mounted) {
        setState(() {
          _remaining = nextRemaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.type.color;
    final secondsRemaining = (_remaining.inMilliseconds / 1000).ceil();
    final progress = _remaining.inMilliseconds / widget.duration.inMilliseconds;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + ZeniSpacing.lg,
      left: ZeniSpacing.lg,
      right: ZeniSpacing.lg,
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          liveRegion: true,
          label:
              '${widget.type.semanticLabel}: ${widget.title}. ${widget.message}',
          child: Container(
            padding: const EdgeInsets.all(ZeniSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: ZeniRadius.card,
              boxShadow: ZeniShadows.card,
              border: Border.all(color: typeColor.withValues(alpha: 0.28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.type.icon, color: typeColor, size: 30),
                const SizedBox(width: ZeniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ZeniSpacing.xs),
                      Text(
                        widget.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ZeniSpacing.sm),
                ZeniCountdownRing(
                  progress: progress,
                  secondsRemaining: secondsRemaining,
                  color: typeColor,
                ),
                const SizedBox(width: ZeniSpacing.xs),
                IconButton(
                  tooltip: 'Fechar aviso',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDismissed,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

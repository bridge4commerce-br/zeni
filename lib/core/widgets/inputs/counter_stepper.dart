import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';
import '../../theme/zeni_spacing.dart';

class CounterStepper extends StatelessWidget {
  const CounterStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.suffix,
  });

  final String label;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  bool get _canDecrease => value > min;
  bool get _canIncrease => value < max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ZeniSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ZeniRadius.lg),
        border: Border.all(color: ZeniColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: ZeniSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          _StepperButton(
            tooltip: 'Diminuir $label',
            icon: Icons.remove_rounded,
            enabled: _canDecrease,
            onPressed: () => onChanged((value - step).clamp(min, max)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ZeniSpacing.md),
            child: Semantics(
              label: '$label: $value ${suffix ?? ''}',
              child: Text(
                suffix == null ? '$value' : '$value $suffix',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _StepperButton(
            tooltip: 'Aumentar $label',
            icon: Icons.add_rounded,
            enabled: _canIncrease,
            onPressed: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
    );
  }
}

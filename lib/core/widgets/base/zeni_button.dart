import 'package:flutter/material.dart';

import '../../layout/zeni_responsive.dart';
import '../../theme/zeni_colors.dart';
import '../../theme/zeni_typography.dart';
import '../../theme/zeni_visual_mode.dart';

enum ZeniButtonRole { primary, secondary, tertiary, destructive }

class ZeniButton extends StatelessWidget {
  const ZeniButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.role,
    required this.mode,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZeniButtonRole role;
  final ZeniVisualMode mode;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final expression = ZeniVisualExpression.resolve(mode);
    final typography = ZeniTypography.of(context);
    final minimumHeight = role == ZeniButtonRole.primary
        ? expression.primaryActionHeight
        : ZeniTouchTargets.minimum;
    final enabledPressed = loading ? null : onPressed;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, minimumHeight)),
      textStyle: WidgetStatePropertyAll(typography.button),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(expression.surfaceRadius),
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        final isDisabled = states.contains(WidgetState.disabled);
        if (role == ZeniButtonRole.destructive) {
          final color = Theme.of(context).colorScheme.onError;
          return isDisabled ? color.withValues(alpha: .55) : color;
        }
        if (role == ZeniButtonRole.primary) {
          return isDisabled
              ? colors.onActionPrimary.withValues(alpha: .55)
              : colors.onActionPrimary;
        }
        final color = role == ZeniButtonRole.secondary
            ? colors.actionPrimary
            : colors.textPrimary;
        return isDisabled ? color.withValues(alpha: .45) : color;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final isDisabled = states.contains(WidgetState.disabled);
        if (role == ZeniButtonRole.destructive) {
          final color = Theme.of(context).colorScheme.error;
          return isDisabled ? color.withValues(alpha: .38) : color;
        }
        if (role != ZeniButtonRole.primary) return Colors.transparent;
        if (isDisabled) return colors.actionPrimary.withValues(alpha: .38);
        return states.contains(WidgetState.pressed)
            ? colors.actionPrimaryPressed
            : colors.actionPrimary;
      }),
      side: WidgetStatePropertyAll(
        role == ZeniButtonRole.secondary
            ? BorderSide(color: colors.actionPrimary)
            : BorderSide.none,
      ),
    );

    final labelWidget = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: loading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  role == ZeniButtonRole.primary ||
                      role == ZeniButtonRole.destructive
                  ? colors.onActionPrimary
                  : colors.actionPrimary,
            ),
          ),
      ],
    );

    final button = switch (role) {
      ZeniButtonRole.primary || ZeniButtonRole.destructive => FilledButton(
        onPressed: enabledPressed,
        style: style,
        child: labelWidget,
      ),
      ZeniButtonRole.secondary => OutlinedButton(
        onPressed: enabledPressed,
        style: style,
        child: labelWidget,
      ),
      ZeniButtonRole.tertiary => TextButton(
        onPressed: enabledPressed,
        style: style,
        child: labelWidget,
      ),
    };

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

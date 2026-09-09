import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_shadows.dart';
import '../../theme/zeni_visual_mode.dart';

enum ZeniSurfaceRole { plain, grouped, highlight, interactive }

class ZeniSurface extends StatelessWidget {
  const ZeniSurface({
    super.key,
    required this.child,
    required this.role,
    required this.mode,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final ZeniSurfaceRole role;
  final ZeniVisualMode mode;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.zeniColors;
    final expression = ZeniVisualExpression.resolve(mode);
    final isPlain = role == ZeniSurfaceRole.plain;
    final isHighlight = role == ZeniSurfaceRole.highlight;
    final isInteractive = role == ZeniSurfaceRole.interactive;
    final borderRadius = BorderRadius.circular(expression.surfaceRadius);

    final content = Container(
      margin: margin,
      padding:
          padding ?? EdgeInsets.all(isPlain ? 0 : expression.surfacePadding),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            switch (role) {
              ZeniSurfaceRole.plain => Colors.transparent,
              ZeniSurfaceRole.grouped ||
              ZeniSurfaceRole.interactive => colors.surface,
              ZeniSurfaceRole.highlight => colors.surfaceSubtle,
            },
        borderRadius: isPlain ? null : borderRadius,
        border: role == ZeniSurfaceRole.grouped || isInteractive
            ? Border.all(color: colors.borderSubtle)
            : null,
        boxShadow: isHighlight ? ZeniShadows.level1 : ZeniShadows.level0,
      ),
      child: child,
    );

    if (!isInteractive || onTap == null) return content;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

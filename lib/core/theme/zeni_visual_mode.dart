enum ZeniVisualMode { kids, parent }

class ZeniVisualExpression {
  const ZeniVisualExpression._({
    required this.mode,
    required this.primaryActionHeight,
    required this.controlHeight,
    required this.surfaceRadius,
    required this.surfacePadding,
    required this.sectionSpacing,
  });

  final ZeniVisualMode mode;
  final double primaryActionHeight;
  final double controlHeight;
  final double surfaceRadius;
  final double surfacePadding;
  final double sectionSpacing;

  static const kids = ZeniVisualExpression._(
    mode: ZeniVisualMode.kids,
    primaryActionHeight: 56,
    controlHeight: 48,
    surfaceRadius: 24,
    surfacePadding: 24,
    sectionSpacing: 32,
  );

  static const parent = ZeniVisualExpression._(
    mode: ZeniVisualMode.parent,
    primaryActionHeight: 48,
    controlHeight: 48,
    surfaceRadius: 16,
    surfacePadding: 16,
    sectionSpacing: 32,
  );

  static ZeniVisualExpression resolve(ZeniVisualMode mode) => switch (mode) {
    ZeniVisualMode.kids => kids,
    ZeniVisualMode.parent => parent,
  };
}

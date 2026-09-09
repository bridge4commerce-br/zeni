import 'package:flutter/material.dart';

import '../../../../core/layout/zeni_responsive.dart';

/// Local reading-scale tokens for the responsible's mission lists.
///
/// The larger styles apply only once the layout has enough room for them;
/// compact and medium keep the established mobile hierarchy unchanged.
class ParentMissionTypography {
  const ParentMissionTypography._();

  static TextStyle? sectionTitle(BuildContext context) =>
      _scaled(context, Theme.of(context).textTheme.titleLarge);

  static TextStyle? missionTitle(BuildContext context, {TextStyle? base}) =>
      _scaled(context, base ?? Theme.of(context).textTheme.titleLarge);

  static TextStyle? metadata(BuildContext context, {Color? color}) => _scaled(
    context,
    Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
  );

  static TextStyle? filterLabel(BuildContext context) =>
      _scaled(context, Theme.of(context).textTheme.labelLarge);

  static TextStyle? actionLabel(BuildContext context) =>
      _scaled(context, Theme.of(context).textTheme.labelLarge);

  static TextStyle? _scaled(BuildContext context, TextStyle? style) {
    final windowClass = ZeniResponsive.windowClass(context);
    final usesTabletReadingScale =
        windowClass == ZeniWindowClass.expanded ||
        windowClass == ZeniWindowClass.large;
    final fontSize = style?.fontSize;

    if (!usesTabletReadingScale || fontSize == null) return style;

    return style!.copyWith(fontSize: fontSize * 1.12);
  }
}

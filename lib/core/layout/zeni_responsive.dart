import 'package:flutter/widgets.dart';

enum ZeniWindowClass { compact, medium, expanded, large }

enum ZeniPageWidth { focus, main, dashboard }

class ZeniResponsive {
  const ZeniResponsive._();

  static ZeniWindowClass windowClass(BuildContext context) =>
      windowClassForWidth(MediaQuery.sizeOf(context).width);
  static ZeniWindowClass sizeOf(BuildContext context) => windowClass(context);

  static ZeniWindowClass windowClassForWidth(double width) => switch (width) {
    < 600 => ZeniWindowClass.compact,
    < 840 => ZeniWindowClass.medium,
    < 1200 => ZeniWindowClass.expanded,
    _ => ZeniWindowClass.large,
  };
  static ZeniWindowClass sizeForWidth(double width) =>
      windowClassForWidth(width);

  static bool isTablet(BuildContext context) =>
      sizeOf(context) != ZeniWindowClass.compact;

  static double horizontalPadding(BuildContext context) =>
      horizontalPaddingForWidth(MediaQuery.sizeOf(context).width);

  static double horizontalPaddingForWidth(double width) =>
      switch (windowClassForWidth(width)) {
        ZeniWindowClass.compact => 24,
        ZeniWindowClass.medium => 32,
        ZeniWindowClass.expanded => 48,
        ZeniWindowClass.large => 64,
      };

  static double focusMaxWidth(BuildContext context) =>
      focusMaxWidthForWidth(MediaQuery.sizeOf(context).width);
  static double focusMaxWidthForWidth(double width) =>
      _widthFor(windowClassForWidth(width), [double.infinity, 560, 680, 720]);
  static double mainMaxWidth(BuildContext context) =>
      mainMaxWidthForWidth(MediaQuery.sizeOf(context).width);
  static double mainMaxWidthForWidth(double width) =>
      _widthFor(windowClassForWidth(width), [double.infinity, 760, 928, 1120]);
  static double dashboardMaxWidth(BuildContext context) =>
      dashboardMaxWidthForWidth(MediaQuery.sizeOf(context).width);
  static double dashboardMaxWidthForWidth(double width) =>
      _widthFor(windowClassForWidth(width), [double.infinity, 760, 960, 1200]);
  static double contentMaxWidth(BuildContext context) => mainMaxWidth(context);
  static double _widthFor(ZeniWindowClass windowClass, List<double> values) =>
      values[windowClass.index];
}

class ZeniPageFrame extends StatelessWidget {
  const ZeniPageFrame({
    super.key,
    required this.child,
    this.width = ZeniPageWidth.focus,
  });
  final Widget child;
  final ZeniPageWidth width;
  @override
  Widget build(BuildContext context) {
    final max = switch (width) {
      ZeniPageWidth.focus => ZeniResponsive.focusMaxWidth(context),
      ZeniPageWidth.main => ZeniResponsive.mainMaxWidth(context),
      ZeniPageWidth.dashboard => ZeniResponsive.dashboardMaxWidth(context),
    };
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ZeniResponsive.horizontalPadding(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: max),
          child: child,
        ),
      ),
    );
  }
}

class ZeniTouchTargets {
  const ZeniTouchTargets._();
  static const double minimum = 48;
  static const double childPriority = 56;
}

class ZeniAdaptiveGrid {
  const ZeniAdaptiveGrid._();
  static int columnsForWidth({
    required double availableWidth,
    required ZeniWindowClass windowClass,
    required double minItemWidth,
  }) {
    final maximum = switch (windowClass) {
      ZeniWindowClass.compact => 1,
      ZeniWindowClass.medium || ZeniWindowClass.expanded => 2,
      ZeniWindowClass.large => 3,
    };
    return (availableWidth / minItemWidth).floor().clamp(1, maximum);
  }

  static int columnsFor(BuildContext context, {required double minItemWidth}) {
    final available =
        MediaQuery.sizeOf(context).width -
        ZeniResponsive.horizontalPadding(context) * 2;
    return columnsForWidth(
      availableWidth: available,
      windowClass: ZeniResponsive.windowClass(context),
      minItemWidth: minItemWidth,
    );
  }
}

class ZeniAdaptiveModal {
  const ZeniAdaptiveModal._();

  static bool usesDialog(BuildContext context) =>
      ZeniResponsive.isTablet(context);
  static double maxWidth(BuildContext context) =>
      maxWidthFor(ZeniResponsive.windowClass(context));
  static double maxWidthFor(ZeniWindowClass windowClass) =>
      switch (windowClass) {
        ZeniWindowClass.compact => double.infinity,
        ZeniWindowClass.medium => 520,
        ZeniWindowClass.expanded => 600,
        ZeniWindowClass.large => 640,
      };
}

/// Constrains adaptive modal content and ensures it can scroll when necessary.
///
/// The caller chooses the presentation using [ZeniAdaptiveModal.usesDialog]: a
/// bottom sheet on compact windows and a dialog on larger windows.
class ZeniAdaptiveModalFrame extends StatelessWidget {
  const ZeniAdaptiveModalFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ZeniAdaptiveModal.maxWidth(context),
        maxHeight: viewport.height * .9,
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/layout/zeni_responsive.dart';

void main() {
  test('classifies responsive widths', () {
    expect(ZeniResponsive.windowClassForWidth(390), ZeniWindowClass.compact);
    expect(ZeniResponsive.windowClassForWidth(768), ZeniWindowClass.medium);
    expect(ZeniResponsive.windowClassForWidth(1024), ZeniWindowClass.expanded);
    expect(ZeniResponsive.windowClassForWidth(1366), ZeniWindowClass.large);
  });

  test('provides width tokens for every responsive window class', () {
    expect(ZeniResponsive.horizontalPaddingForWidth(390), 24);
    expect(ZeniResponsive.horizontalPaddingForWidth(768), 32);
    expect(ZeniResponsive.horizontalPaddingForWidth(1024), 48);
    expect(ZeniResponsive.horizontalPaddingForWidth(1366), 64);

    expect(ZeniResponsive.focusMaxWidthForWidth(390), double.infinity);
    expect(ZeniResponsive.focusMaxWidthForWidth(768), 560);
    expect(ZeniResponsive.focusMaxWidthForWidth(1024), 680);
    expect(ZeniResponsive.focusMaxWidthForWidth(1366), 720);
    expect(ZeniResponsive.mainMaxWidthForWidth(390), double.infinity);
    expect(ZeniResponsive.mainMaxWidthForWidth(768), 760);
    expect(ZeniResponsive.mainMaxWidthForWidth(1024), 928);
    expect(ZeniResponsive.mainMaxWidthForWidth(1366), 1120);
    expect(ZeniResponsive.dashboardMaxWidthForWidth(390), double.infinity);
    expect(ZeniResponsive.dashboardMaxWidthForWidth(768), 760);
    expect(ZeniResponsive.dashboardMaxWidthForWidth(1024), 960);
    expect(ZeniResponsive.dashboardMaxWidthForWidth(1366), 1200);
  });

  testWidgets('exposes padding, widths and structural helpers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(
            builder: (context) {
              expect(ZeniResponsive.horizontalPadding(context), 48);
              expect(ZeniResponsive.focusMaxWidth(context), 680);
              expect(ZeniResponsive.mainMaxWidth(context), 928);
              expect(ZeniResponsive.dashboardMaxWidth(context), 960);
              expect(
                ZeniAdaptiveGrid.columnsFor(context, minItemWidth: 500),
                1,
              );
              expect(ZeniAdaptiveModal.usesDialog(context), isTrue);
              expect(ZeniAdaptiveModal.maxWidth(context), 600);
              return const ZeniPageFrame(
                child: ZeniAdaptiveModalFrame(child: Text('frame')),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('frame'), findsOneWidget);
  });

  test('adaptive grid respects item minimums and touch targets', () {
    expect(
      ZeniAdaptiveGrid.columnsForWidth(
        availableWidth: 400,
        windowClass: ZeniWindowClass.compact,
        minItemWidth: 180,
      ),
      1,
    );
    expect(
      ZeniAdaptiveGrid.columnsForWidth(
        availableWidth: 700,
        windowClass: ZeniWindowClass.medium,
        minItemWidth: 300,
      ),
      2,
    );
    expect(
      ZeniAdaptiveGrid.columnsForWidth(
        availableWidth: 700,
        windowClass: ZeniWindowClass.large,
        minItemWidth: 300,
      ),
      2,
    );
    expect(ZeniTouchTargets.minimum, 48);
    expect(ZeniTouchTargets.childPriority, 56);
  });

  test('adaptive modal has the expected presentation widths', () {
    expect(
      ZeniAdaptiveModal.maxWidthFor(ZeniWindowClass.compact),
      double.infinity,
    );
    expect(ZeniAdaptiveModal.maxWidthFor(ZeniWindowClass.medium), 520);
    expect(ZeniAdaptiveModal.maxWidthFor(ZeniWindowClass.expanded), 600);
    expect(ZeniAdaptiveModal.maxWidthFor(ZeniWindowClass.large), 640);
  });
}

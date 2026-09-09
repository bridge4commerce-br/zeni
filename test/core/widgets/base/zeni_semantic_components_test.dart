import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/layout/zeni_responsive.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_visual_mode.dart';
import 'package:zeni/core/widgets/base/zeni_button.dart';
import 'package:zeni/core/widgets/base/zeni_choice_chip.dart';
import 'package:zeni/core/widgets/base/zeni_icon_action_button.dart';
import 'package:zeni/core/widgets/base/zeni_surface.dart';

Widget harness(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ZeniTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets(
    'surfaces express plain grouped highlight and interactive roles',
    (tester) async {
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ZeniSurface(
                role: ZeniSurfaceRole.plain,
                mode: ZeniVisualMode.parent,
                child: Text('plain'),
              ),
              const ZeniSurface(
                role: ZeniSurfaceRole.grouped,
                mode: ZeniVisualMode.parent,
                child: Text('grouped'),
              ),
              const ZeniSurface(
                role: ZeniSurfaceRole.highlight,
                mode: ZeniVisualMode.kids,
                child: Text('highlight'),
              ),
              ZeniSurface(
                role: ZeniSurfaceRole.interactive,
                mode: ZeniVisualMode.parent,
                onTap: () {},
                child: const Text('interactive'),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ZeniSurface), findsNWidgets(4));
      expect(find.byType(InkWell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('buttons expose all roles and preserve semantic touch targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZeniButton(
              label: 'Kids primary',
              onPressed: () {},
              role: ZeniButtonRole.primary,
              mode: ZeniVisualMode.kids,
            ),
            ZeniButton(
              label: 'Parent secondary',
              onPressed: () {},
              role: ZeniButtonRole.secondary,
              mode: ZeniVisualMode.parent,
            ),
            ZeniButton(
              label: 'Tertiary',
              onPressed: () {},
              role: ZeniButtonRole.tertiary,
              mode: ZeniVisualMode.parent,
            ),
            ZeniButton(
              label: 'Destructive',
              onPressed: () {},
              role: ZeniButtonRole.destructive,
              mode: ZeniVisualMode.parent,
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(FilledButton).first).height, 56);
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(ZeniTouchTargets.minimum),
    );
    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips expose normal selected and disabled states', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Wrap(
          children: [
            ZeniChoiceChip(
              label: 'Normal',
              selected: false,
              mode: ZeniVisualMode.parent,
              onSelected: (_) {},
            ),
            ZeniChoiceChip(
              label: 'Selected',
              selected: true,
              mode: ZeniVisualMode.kids,
              onSelected: (_) {},
            ),
            const ZeniChoiceChip(
              label: 'Disabled',
              selected: false,
              enabled: false,
              mode: ZeniVisualMode.parent,
              onSelected: null,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(tester.getSize(find.text('Normal')).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon actions default to the universal touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ZeniIconActionButton(
          icon: Icons.edit,
          tooltip: 'Editar',
          onPressed: () {},
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(ZeniIconActionButton)),
      const Size.square(ZeniTouchTargets.minimum),
    );
  });

  testWidgets('semantic components render in dark mode', (tester) async {
    await tester.pumpWidget(
      harness(
        const ZeniSurface(
          role: ZeniSurfaceRole.highlight,
          mode: ZeniVisualMode.kids,
          child: ZeniChoiceChip(
            label: 'Escuro',
            selected: true,
            mode: ZeniVisualMode.kids,
            onSelected: null,
          ),
        ),
        theme: ZeniTheme.dark,
      ),
    );

    expect(find.text('Escuro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

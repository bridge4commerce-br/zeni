import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/widgets/base/zeni_balance_pill.dart';

void main() {
  testWidgets('announces the local balance with its label', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(home: ZeniBalancePill(stars: 12, label: 'estrelas')),
    );

    expect(
      tester.getSemantics(find.byType(ZeniBalancePill)),
      matchesSemantics(label: '12 estrelas'),
    );
    semantics.dispose();
  });
}

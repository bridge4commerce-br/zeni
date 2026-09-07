import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/widgets/zeni_mascot.dart';

void main() {
  test('maps every mascot state to its official WebP asset', () {
    expect(
      ZeniMascotState.idle.assetPath,
      'assets/mascot/webp/zeni_mascot_idle.webp',
    );
    expect(
      ZeniMascotState.encourage.assetPath,
      'assets/mascot/webp/zeni_mascot_encourage.webp',
    );
    expect(
      ZeniMascotState.waitingApproval.assetPath,
      'assets/mascot/webp/zeni_mascot_waiting_approval.webp',
    );
    expect(
      ZeniMascotState.celebrating.assetPath,
      'assets/mascot/webp/zeni_mascot_celebrating.webp',
    );
    expect(
      ZeniMascotState.sleeping.assetPath,
      'assets/mascot/webp/zeni_mascot_sleeping.webp',
    );
    expect(
      ZeniMascotState.thinking.assetPath,
      'assets/mascot/webp/zeni_mascot_thinking.webp',
    );
    expect(
      ZeniMascotState.rewardClose.assetPath,
      'assets/mascot/webp/zeni_mascot_reward_close.webp',
    );
    expect(
      ZeniMascotState.achievement.assetPath,
      'assets/mascot/webp/zeni_mascot_achievement.webp',
    );
  });

  testWidgets('animates when the mascot state changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ZeniMascot(state: ZeniMascotState.idle)),
    );
    expect(find.byKey(const ValueKey(ZeniMascotState.idle)), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: ZeniMascot(state: ZeniMascotState.celebrating)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey(ZeniMascotState.celebrating)),
      findsOneWidget,
    );
  });

  testWidgets('exposes a descriptive mascot semantic label', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: ZeniMascot(state: ZeniMascotState.waitingApproval),
      ),
    );

    expect(
      tester.getSemantics(find.byType(ZeniMascot)),
      matchesSemantics(label: 'Zeni está aguardando aprovação', isImage: true),
    );
    semantics.dispose();
  });
}

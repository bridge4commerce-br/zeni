import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_colors.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/core/widgets/base/zeni_surface.dart';
import 'package:zeni/features/child/presentation/widgets/child_rewards_tab.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';
import 'package:zeni/features/rewards/presentation/widgets/reward_child_detail_sheet.dart';

void main() {
  Reward reward(int index, {int cost = 20}) => Reward(
    id: 'reward-$index',
    familyId: 'family-1',
    childId: 'child-1',
    title: 'Mimo $index',
    description: 'Descrição completa do mimo $index.',
    emoji: '🎁',
    cost: cost,
    renewal: RewardRenewal.always,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  RewardRequest pending(Reward reward) => RewardRequest(
    id: 'request-${reward.id}',
    rewardId: reward.id,
    childId: 'child-1',
    status: RewardRequestStatus.pending,
    requestedAt: DateTime(2026, 9, 2),
  );

  Future<void> pumpRewards(
    WidgetTester tester, {
    required Size size,
    required List<Reward> rewards,
    int childBalance = 40,
    List<RewardRequest> pendingRequests = const [],
    ValueChanged<Reward>? onRedeem,
    bool darkMode = false,
    bool openDyslexic = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rewardsById = {for (final item in rewards) item.id: item};
    final baseTheme = darkMode ? ZeniTheme.dark : ZeniTheme.light;
    final theme = openDyslexic
        ? baseTheme.copyWith(
            textTheme: ZeniTypography.applyFontFamily(
              baseTheme.textTheme,
              ZeniTypography.openDyslexicFontFamily,
            ),
            primaryTextTheme: ZeniTypography.applyFontFamily(
              baseTheme.primaryTextTheme,
              ZeniTypography.openDyslexicFontFamily,
            ),
          )
        : baseTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: ChildRewardsTab(
            childBalance: childBalance,
            rewards: rewards,
            pendingRewardRequests: pendingRequests,
            rewardById: (id) => rewardsById[id],
            onRedeemReward: onRedeem ?? (_) {},
            onListenToReward: (_) {},
            onListenToRewardDetails: (_, _) {},
            canListenToReward: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone keeps rewards in one vertical column', (tester) async {
    final rewards = [reward(1), reward(2), reward(3)];
    await pumpRewards(tester, size: const Size(390, 844), rewards: rewards);

    expect(find.byKey(const Key('child-rewards-title')), findsOneWidget);
    expect(find.byKey(const Key('child-rewards-balance')), findsOneWidget);
    final first = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-1')),
    );
    final second = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-2')),
    );
    final third = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-3')),
    );
    expect(second.dy, greaterThan(first.dy));
    expect(third.dy, greaterThan(second.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet portrait keeps rewards in one grouped list', (
    tester,
  ) async {
    final rewards = [reward(1), reward(2), reward(3), reward(4)];
    await pumpRewards(tester, size: const Size(1024, 1366), rewards: rewards);

    final first = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-1')),
    );
    final second = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-2')),
    );
    final third = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-3')),
    );
    expect((second.dx - first.dx).abs(), lessThan(1));
    expect(second.dy, greaterThan(first.dy));
    expect(third.dy, greaterThan(first.dy));

    await tester.tap(find.byKey(const Key('child-reward-reward-1')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(RewardChildDetailSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rewards catalog uses one grouped surface with dividers', (
    tester,
  ) async {
    final rewards = [reward(1), reward(2), reward(3), reward(4)];
    await pumpRewards(tester, size: const Size(1024, 1366), rewards: rewards);

    final list = find.byKey(const Key('child-rewards-catalog-list'));
    final surface = tester.widget<ZeniSurface>(list);
    expect(surface.role, ZeniSurfaceRole.grouped);
    expect(surface.padding, EdgeInsets.zero);
    expect(
      find.descendant(of: list, matching: find.byType(Divider)),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large landscape preserves the same grouped list anatomy', (
    tester,
  ) async {
    final rewards = [reward(1), reward(2), reward(3), reward(4)];
    await pumpRewards(tester, size: const Size(1366, 1024), rewards: rewards);

    final first = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-1')),
    );
    final second = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-2')),
    );
    final third = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-3')),
    );
    final fourth = tester.getTopLeft(
      find.byKey(const Key('child-reward-reward-4')),
    );
    expect((second.dx - first.dx).abs(), lessThan(1));
    expect((third.dx - first.dx).abs(), lessThan(1));
    expect(second.dy, greaterThan(first.dy));
    expect(third.dy, greaterThan(second.dy));
    expect(fourth.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one tablet reward uses the grouped list width', (tester) async {
    await pumpRewards(
      tester,
      size: const Size(1024, 1366),
      rewards: [reward(1)],
    );

    final card = find.byKey(const Key('child-reward-reward-1'));
    final balance = find.byKey(const Key('child-rewards-balance'));
    expect(
      tester.getSize(card).width,
      closeTo(tester.getSize(balance).width, 2.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty catalog shows a friendly empty state', (tester) async {
    await pumpRewards(tester, size: const Size(390, 844), rewards: const []);

    expect(find.byKey(const Key('child-rewards-empty-state')), findsOneWidget);
    expect(find.text('Nenhum mimo por enquanto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sufficient balance returns the redeem action from phone detail',
    (tester) async {
      final item = reward(1, cost: 20);
      Reward? redeemed;
      await pumpRewards(
        tester,
        size: const Size(390, 844),
        rewards: [item],
        childBalance: 40,
        onRedeem: (reward) => redeemed = reward,
      );

      await tester.ensureVisible(
        find.byKey(const Key('child-reward-reward-1')),
      );
      await tester.tap(find.byKey(const Key('child-reward-reward-1')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Seu saldo'), findsWidgets);
      expect(find.text('40 estrelas'), findsOneWidget);
      await tester.tap(find.text('Pedir mimo'));
      await tester.pumpAndSettle();
      expect(redeemed, item);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('insufficient balance keeps redeem unavailable', (tester) async {
    final item = reward(1, cost: 20);
    var redeemCalls = 0;
    await pumpRewards(
      tester,
      size: const Size(390, 844),
      rewards: [item],
      childBalance: 5,
      onRedeem: (_) => redeemCalls += 1,
    );

    await tester.ensureVisible(find.byKey(const Key('child-reward-reward-1')));
    await tester.tap(find.byKey(const Key('child-reward-reward-1')));
    await tester.pumpAndSettle();
    expect(find.text('Faltam 15 estrelas para pedir.'), findsNWidgets(2));
    expect(find.text('Pedir mimo'), findsNothing);
    await tester.tap(find.text('Continuar juntando estrelas'));
    await tester.pumpAndSettle();
    expect(redeemCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('insufficient balance uses a neutral surface and amber status', (
    tester,
  ) async {
    await pumpRewards(
      tester,
      size: const Size(390, 844),
      rewards: [reward(1, cost: 20)],
      childBalance: 5,
    );

    final card = find.byKey(const Key('child-reward-reward-1'));
    final surface = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );

    final status = tester.widget<Text>(
      find.descendant(of: card, matching: find.text('Faltam 15 estrelas')),
    );

    expect(surface.color, ZeniSemanticColors.light.surface);
    expect(status.style?.color, ZeniColors.warning);
    expect(tester.takeException(), isNull);
  });

  testWidgets('available reward uses a neutral surface and green status', (
    tester,
  ) async {
    await pumpRewards(
      tester,
      size: const Size(390, 844),
      rewards: [reward(1, cost: 20)],
      childBalance: 40,
    );

    final card = find.byKey(const Key('child-reward-reward-1'));
    final surface = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );

    final status = tester.widget<Text>(
      find.descendant(of: card, matching: find.text('Pode pedir agora')),
    );

    expect(surface.color, ZeniSemanticColors.light.surface);
    expect(status.style?.color, ZeniSemanticColors.light.actionPrimary);
    expect(tester.getSize(card).height, lessThanOrEqualTo(112));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending request is clear in card and detail', (tester) async {
    final item = reward(1);
    await pumpRewards(
      tester,
      size: const Size(1024, 1366),
      rewards: [item],
      pendingRequests: [pending(item)],
    );

    expect(find.text('Aguardando responsável'), findsNWidgets(2));
    final card = find.byKey(const Key('child-reward-reward-1'));
    final surface = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );
    final status = tester.widget<Text>(
      find.descendant(of: card, matching: find.text('Aguardando responsável')),
    );
    expect(surface.color, ZeniSemanticColors.light.surface);
    expect(status.style?.color, ZeniColors.warning);
    await tester.tap(find.byKey(const Key('child-reward-reward-1')));
    await tester.pumpAndSettle();
    expect(find.text('Pedido aguardando o responsável.'), findsOneWidget);
    expect(find.text('Aguardando responsável'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dark OpenDyslexic tablet supports larger text without overflow',
    (tester) async {
      await pumpRewards(
        tester,
        size: const Size(1024, 1366),
        rewards: [reward(1), reward(2), reward(3)],
        darkMode: true,
        openDyslexic: true,
        textScale: 1.35,
      );

      final title = tester.widget<Text>(
        find.byKey(const Key('child-rewards-title')),
      );
      expect(title.style?.fontFamily, ZeniTypography.openDyslexicFontFamily);
      final card = find.byKey(const Key('child-reward-reward-1'));
      final surface = tester.widget<Material>(
        find.descendant(of: card, matching: find.byType(Material)).first,
      );
      expect(surface.color, ZeniSemanticColors.dark.surface);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

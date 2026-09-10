import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/theme/zeni_theme.dart';
import 'package:zeni/core/theme/zeni_typography.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/parent/presentation/widgets/parent_rewards_tab.dart';
import 'package:zeni/features/rewards/data/models/reward.dart';
import 'package:zeni/features/rewards/data/models/reward_request.dart';

void main() {
  final now = DateTime(2026, 9, 10);
  final luna = ChildProfile(
    id: 'luna',
    familyId: 'family',
    name: 'Luna',
    emoji: '🦊',
    starBalance: 0,
    streakCount: 0,
    createdAt: now,
  );
  final theo = ChildProfile(
    id: 'theo',
    familyId: 'family',
    name: 'Theo',
    emoji: '🦁',
    starBalance: 0,
    streakCount: 0,
    createdAt: now,
  );
  Reward reward(
    String id,
    ChildProfile child,
    String title, {
    bool active = true,
  }) => Reward(
    id: id,
    familyId: 'family',
    childId: child.id,
    title: title,
    description: 'Descrição.',
    cost: 80,
    renewal: RewardRenewal.weekly,
    isActive: active,
    createdAt: now,
    updatedAt: now,
  );
  RewardRequest request(String id, Reward item) => RewardRequest(
    id: id,
    rewardId: item.id,
    childId: item.childId!,
    status: RewardRequestStatus.pending,
    requestedAt: now,
  );

  Future<void> pumpRewards(
    WidgetTester tester, {
    required Size size,
    List<Reward>? active,
    List<Reward>? archived,
    List<RewardRequest>? pending,
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
    ValueChanged<List<RewardRequest>>? onApproveBatch,
    ValueChanged<List<RewardRequest>>? onRejectBatch,
    ValueChanged<Reward>? onArchive,
    ValueChanged<Reward>? onRestore,
  }) async {
    final activeRewards =
        active ??
        [
          reward('reward-luna', luna, 'Filme em família'),
          reward('reward-theo', theo, 'Noite de jogos'),
        ];
    final archivedRewards =
        archived ??
        [reward('reward-archived', luna, 'Livro novo', active: false)];
    final pendingRequests =
        pending ??
        [
          request('request-luna', activeRewards.first),
          request('request-theo', activeRewards.last),
        ];
    final allRewards = [...activeRewards, ...archivedRewards];
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ZeniTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: ParentRewardsTab(
            activeChildren: [luna, theo],
            activeRewards: activeRewards,
            archivedRewards: archivedRewards,
            pendingRequests: pendingRequests,
            childById: (id) =>
                [luna, theo].where((child) => child.id == id).firstOrNull,
            rewardById: (id) =>
                allRewards.where((item) => item.id == id).firstOrNull,
            onApproveRewardRequest: (_) {},
            onRejectRewardRequest: (_) {},
            onApproveRewardRequestBatch: onApproveBatch ?? (_) {},
            onRejectRewardRequestBatch: onRejectBatch ?? (_) {},
            onEditReward: (_) {},
            onArchiveReward: onArchive ?? (_) {},
            onRestoreReward: onRestore ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses V2 grouped composition on compact and filters children', (
    tester,
  ) async {
    await pumpRewards(tester, size: const Size(390, 844));
    expect(
      find.byKey(const Key('parent-rewards-single-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('parent-rewards-pending-list')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('parent-rewards-active-list')), findsOneWidget);
    await tester.tap(find.text('Theo'));
    await tester.pumpAndSettle();
    expect(find.text('Noite de jogos'), findsWidgets);
    expect(find.text('Filme em família'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection preserves batch approval and rejection callbacks', (
    tester,
  ) async {
    List<RewardRequest>? approved;
    List<RewardRequest>? rejected;
    await pumpRewards(
      tester,
      size: const Size(390, 844),
      onApproveBatch: (items) => approved = items,
      onRejectBatch: (items) => rejected = items,
    );
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('parent-reward-request-request-luna')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('parent-rewards-batch-actions')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Aprovar'));
    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();
    expect(approved?.single.id, 'request-luna');
    await tester.ensureVisible(find.text('Selecionar'));
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('parent-reward-request-request-luna')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rejeitar'));
    await tester.tap(find.text('Rejeitar'));
    await tester.pumpAndSettle();
    expect(rejected?.single.id, 'request-luna');
  });

  testWidgets('expands archived rewards and uses split layout on large', (
    tester,
  ) async {
    Reward? restored;
    await pumpRewards(
      tester,
      size: const Size(1366, 1024),
      onRestore: (item) => restored = item,
    );
    expect(
      find.byKey(const Key('parent-rewards-split-layout')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('parent-rewards-archived-toggle')),
    );
    await tester.tap(find.byKey(const Key('parent-rewards-archived-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restaurar mimo'));
    expect(restored?.id, 'reward-archived');
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports OpenDyslexic and larger text without overflow', (
    tester,
  ) async {
    final theme = ZeniTheme.light.copyWith(
      textTheme: ZeniTypography.applyFontFamily(
        ZeniTheme.light.textTheme,
        ZeniTypography.openDyslexicFontFamily,
      ),
    );
    await pumpRewards(
      tester,
      size: const Size(390, 844),
      theme: theme,
      textScaler: const TextScaler.linear(1.35),
    );
    expect(find.text('Mimos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

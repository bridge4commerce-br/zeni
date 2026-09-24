import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zeni/app/app_router.dart';

void main() {
  test('development components route is omitted outside debug routes', () {
    final router = createZeniRouter(enableDevRoutes: false);
    addTearDown(router.dispose);

    final paths = router.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );

    expect(paths, isNot(contains('/dev/components')));
  });

  test(
    'development components route is available when debug routes are enabled',
    () {
      final router = createZeniRouter(enableDevRoutes: true);
      addTearDown(router.dispose);

      final paths = router.configuration.routes.whereType<GoRoute>().map(
        (route) => route.path,
      );

      expect(paths, contains('/dev/components'));
    },
  );
}

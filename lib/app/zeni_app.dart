import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/accessibility/zeni_accessibility_controller.dart';
import '../core/accessibility/zeni_accessibility_settings.dart';
import '../core/theme/zeni_theme.dart';
import 'app_router.dart';

class ZeniApp extends ConsumerStatefulWidget {
  const ZeniApp({super.key});

  @override
  ConsumerState<ZeniApp> createState() => _ZeniAppState();
}

class _ZeniAppState extends ConsumerState<ZeniApp> {
  late final GoRouter _router = createZeniRouter();

  @override
  Widget build(BuildContext context) {
    final accessibility = ref.watch(zeniAccessibilityControllerProvider);
    final settings = accessibility.settings;

    return MaterialApp.router(
      title: 'ZeniKids',
      debugShowCheckedModeBanner: false,
      theme: _applyAccessibilityTheme(ZeniTheme.light, settings),
      darkTheme: _applyAccessibilityTheme(ZeniTheme.dark, settings),
      themeMode: settings.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  ThemeData _applyAccessibilityTheme(
    ThemeData theme,
    ZeniAccessibilitySettings settings,
  ) {
    final fontFamily = settings.fontFamily;
    if (fontFamily == null) return theme;

    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }
}

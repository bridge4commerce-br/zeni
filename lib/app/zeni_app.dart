import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/accessibility/zeni_accessibility_controller.dart';
import '../core/accessibility/zeni_accessibility_settings.dart';
import '../core/theme/zeni_theme.dart';
import '../core/theme/zeni_typography.dart';
import '../features/sync/presentation/providers/opportunistic_sync_providers.dart';
import 'app_router.dart';

class ZeniApp extends ConsumerStatefulWidget {
  const ZeniApp({super.key});

  @override
  ConsumerState<ZeniApp> createState() => _ZeniAppState();
}

class _ZeniAppState extends ConsumerState<ZeniApp> with WidgetsBindingObserver {
  late final GoRouter _router = createZeniRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
        .read(zeniOpportunisticSyncControllerProvider)
        .scheduleSync(reason: 'app_resumed');
  }

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
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ja'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      textTheme: ZeniTypography.applyFontFamily(theme.textTheme, fontFamily),
      primaryTextTheme: ZeniTypography.applyFontFamily(
        theme.primaryTextTheme,
        fontFamily,
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class ZeniSupabaseConfig {
  const ZeniSupabaseConfig({required this.url, required this.anonKey});

  factory ZeniSupabaseConfig.fromEnvironment() {
    return const ZeniSupabaseConfig(
      url: String.fromEnvironment('SUPABASE_URL'),
      anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  final String url;
  final String anonKey;

  bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

class ZeniSupabaseBootstrapState {
  const ZeniSupabaseBootstrapState({
    required this.isConfigured,
    required this.isInitialized,
    this.message,
  });

  const ZeniSupabaseBootstrapState.unconfigured()
    : this(
        isConfigured: false,
        isInitialized: false,
        message: 'Supabase não configurado.',
      );

  const ZeniSupabaseBootstrapState.initialized()
    : this(isConfigured: true, isInitialized: true);

  const ZeniSupabaseBootstrapState.failed(String message)
    : this(isConfigured: true, isInitialized: false, message: message);

  final bool isConfigured;
  final bool isInitialized;
  final String? message;

  bool get isAvailable => isConfigured && isInitialized;
}

typedef ZeniSupabaseInitializer =
    Future<void> Function({required String url, required String anonKey});

class ZeniSupabaseBootstrap {
  static ZeniSupabaseBootstrapState _state =
      const ZeniSupabaseBootstrapState.unconfigured();

  static ZeniSupabaseBootstrapState get state => _state;

  static SupabaseClient? get client {
    if (!_state.isAvailable) return null;
    return Supabase.instance.client;
  }

  static Future<ZeniSupabaseBootstrapState> initialize({
    ZeniSupabaseConfig? config,
    ZeniSupabaseInitializer? initializeOverride,
  }) async {
    final resolvedConfig = config ?? ZeniSupabaseConfig.fromEnvironment();

    if (!resolvedConfig.isConfigured) {
      _state = const ZeniSupabaseBootstrapState.unconfigured();
      return _state;
    }

    if (_state.isAvailable) {
      return _state;
    }

    try {
      final initializer = initializeOverride ?? _defaultInitialize;
      await initializer(
        url: resolvedConfig.url,
        anonKey: resolvedConfig.anonKey,
      );
      _state = const ZeniSupabaseBootstrapState.initialized();
      return _state;
    } catch (error) {
      _state = ZeniSupabaseBootstrapState.failed(error.toString());
      return _state;
    }
  }

  static Future<void> _defaultInitialize({
    required String url,
    required String anonKey,
  }) {
    return Supabase.initialize(url: url, anonKey: anonKey);
  }

  static void resetForTests() {
    _state = const ZeniSupabaseBootstrapState.unconfigured();
  }
}

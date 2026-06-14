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

  List<String> get missingKeys {
    final keys = <String>[];
    if (url.trim().isEmpty) {
      keys.add('SUPABASE_URL');
    }
    if (anonKey.trim().isEmpty) {
      keys.add('SUPABASE_ANON_KEY');
    }
    return keys;
  }

  String get missingConfigurationMessage {
    if (missingKeys.isEmpty) {
      return 'Supabase configurado.';
    }
    return 'Defina ${missingKeys.join(' e ')} para habilitar autenticação, sync, backup e restauração.';
  }
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
        message:
            'Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY para habilitar auth e sync.',
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
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<ZeniSupabaseBootstrapState> initialize({
    ZeniSupabaseConfig? config,
    ZeniSupabaseInitializer? initializeOverride,
  }) async {
    final resolvedConfig = config ?? ZeniSupabaseConfig.fromEnvironment();

    if (!resolvedConfig.isConfigured) {
      _state = ZeniSupabaseBootstrapState(
        isConfigured: false,
        isInitialized: false,
        message: resolvedConfig.missingConfigurationMessage,
      );
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

String zeniRedactTechnicalMessage(String? rawMessage) {
  final message = rawMessage?.trim();
  if (message == null || message.isEmpty) {
    return 'Sem mensagem';
  }

  var sanitized = message.replaceAll(
    RegExp(r'https?://[^\s,)]+'),
    '[url oculta]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(r'([A-Za-z0-9._-]{6})[A-Za-z0-9._-]{6,}'),
    (match) => '${match.group(1)}...',
  );
  return sanitized;
}

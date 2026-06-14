import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_sync_providers.dart';

final zeniOpportunisticSyncControllerProvider =
    Provider<ZeniOpportunisticSyncController>((ref) {
      final controller = ZeniOpportunisticSyncController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });

class ZeniOpportunisticSyncController {
  ZeniOpportunisticSyncController(this._ref);

  final Ref _ref;
  Timer? _debounce;
  Future<void>? _inFlight;

  void scheduleSync({
    required String reason,
    Duration delay = const Duration(milliseconds: 900),
  }) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      unawaited(syncNowBestEffort(reason: reason));
    });
  }

  Future<void> syncNowBestEffort({required String reason}) {
    _debounce?.cancel();
    final inFlight = _inFlight;
    if (inFlight != null) {
      _debugLog('Skipping overlapping sync for $reason');
      return inFlight;
    }

    final future = _ref
        .read(zeniCloudSyncControllerProvider)
        .syncCloudDataNow()
        .then((result) {
          if (!result.isSuccess) {
            _debugLog(
              'Best-effort sync skipped for $reason: ${result.message}',
            );
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          _debugLog('Best-effort sync error for $reason: $error');
        })
        .whenComplete(() {
          _inFlight = null;
        });
    _inFlight = future;
    return future;
  }

  void dispose() {
    _debounce?.cancel();
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniOpportunisticSync] $message');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../data/models/historical_restore_result.dart';
import 'device_bootstrap_providers.dart';
import 'historical_restore_providers.dart';

final firstAccessRestoreControllerProvider =
    Provider<FirstAccessRestoreController>((ref) {
      return FirstAccessRestoreController(ref);
    });

enum FirstAccessRestoreResultStatus {
  success,
  partialSuccess,
  blocked,
  failure,
}

class FirstAccessRestoreResult {
  const FirstAccessRestoreResult({required this.status, required this.message});

  const FirstAccessRestoreResult.success()
    : this(
        status: FirstAccessRestoreResultStatus.success,
        message: 'Família restaurada com sucesso neste aparelho.',
      );

  const FirstAccessRestoreResult.partialSuccess()
    : this(
        status: FirstAccessRestoreResultStatus.partialSuccess,
        message:
            'Família restaurada. Não foi possível restaurar histórico e saldo com segurança agora.',
      );

  const FirstAccessRestoreResult.blocked(String message)
    : this(status: FirstAccessRestoreResultStatus.blocked, message: message);

  const FirstAccessRestoreResult.failure(String message)
    : this(status: FirstAccessRestoreResultStatus.failure, message: message);

  final FirstAccessRestoreResultStatus status;
  final String message;

  bool get isSuccess =>
      status == FirstAccessRestoreResultStatus.success ||
      status == FirstAccessRestoreResultStatus.partialSuccess;
}

class FirstAccessRestoreController {
  const FirstAccessRestoreController(this._ref);

  final Ref _ref;

  Future<FirstAccessRestoreResult> restoreFamilyOnEmptyDevice() async {
    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    if (!_canStartFirstAccessRestore(localState)) {
      return const FirstAccessRestoreResult.blocked(
        'Este aparelho já possui dados locais ou atividade local. A restauração completa foi bloqueada para evitar mistura de dados.',
      );
    }

    final bootstrapResult = await _ref
        .read(deviceBootstrapControllerProvider)
        .bootstrapFromRemoteFamily();
    if (!bootstrapResult.isSuccess) {
      return FirstAccessRestoreResult.failure(
        bootstrapResult.message ??
            'Não foi possível restaurar a família agora.',
      );
    }

    final postBootstrapState = await _ref.read(
      zeniAppStateControllerProvider.future,
    );
    if (!_hasSafeCatalogBaseForHistory(postBootstrapState)) {
      return const FirstAccessRestoreResult.failure(
        'Não foi possível validar a restauração neste aparelho.',
      );
    }

    final historicalResult = await _ref
        .read(historicalRestoreControllerProvider)
        .restoreHistoryIfSafe();

    if (historicalResult.isSuccess) {
      return const FirstAccessRestoreResult.success();
    }

    if (_isSafePartialHistoryBlock(historicalResult.status)) {
      return const FirstAccessRestoreResult.partialSuccess();
    }

    return FirstAccessRestoreResult.failure(historicalResult.message);
  }

  bool _canStartFirstAccessRestore(ZeniAppState state) {
    return !state.hasUserContent &&
        state.missionLogs.isEmpty &&
        state.rewardRequests.isEmpty &&
        state.starLedgerEntries.isEmpty &&
        state.children.every((child) => child.starBalance == 0);
  }

  bool _hasSafeCatalogBaseForHistory(ZeniAppState state) {
    return state.children.isNotEmpty &&
        state.missionLogs.isEmpty &&
        state.rewardRequests.isEmpty &&
        state.starLedgerEntries.isEmpty &&
        state.children.every((child) => child.starBalance == 0);
  }

  bool _isSafePartialHistoryBlock(HistoricalRestoreResultStatus status) {
    return status == HistoricalRestoreResultStatus.remoteHistoryMissing ||
        status == HistoricalRestoreResultStatus.unsafeBalanceMismatch;
  }
}

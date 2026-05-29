import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../models/star_ledger_entry.dart';
import 'balance_repository.dart';

class MockBalanceRepository implements BalanceRepository {
  MockBalanceRepository(this._ref);

  final Ref _ref;

  @override
  Future<List<StarLedgerEntry>> getLedgerForChild(String childId) async {
    return (await _ref.read(
        zeniAppStateControllerProvider.future,
      )).starLedgerEntries.where((entry) => entry.childId == childId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

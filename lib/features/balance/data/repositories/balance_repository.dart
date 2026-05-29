import '../models/star_ledger_entry.dart';

abstract class BalanceRepository {
  Future<List<StarLedgerEntry>> getLedgerForChild(String childId);
}

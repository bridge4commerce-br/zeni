class RemoteChildStarBalance {
  const RemoteChildStarBalance({
    required this.familyId,
    required this.childId,
    required this.childName,
    required this.creditsTotal,
    required this.debitsTotal,
    required this.derivedBalance,
    required this.ledgerEventsCount,
    this.lastLedgerEventAt,
  });

  final String familyId;
  final String childId;
  final String childName;
  final int creditsTotal;
  final int debitsTotal;
  final int derivedBalance;
  final int ledgerEventsCount;
  final DateTime? lastLedgerEventAt;
}

abstract class RemoteChildBalanceRepository {
  bool get isConfigured;

  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  });
}

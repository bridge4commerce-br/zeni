class ChildBalanceDiagnostic {
  const ChildBalanceDiagnostic({
    required this.childName,
    required this.localBalance,
    required this.remoteBalance,
    required this.ledgerEventsCount,
  });

  final String childName;
  final int localBalance;
  final int remoteBalance;
  final int ledgerEventsCount;

  bool get isMatching => localBalance == remoteBalance;
}

class CloudConsistencyDiagnostic {
  const CloudConsistencyDiagnostic({
    required this.localChildrenCount,
    required this.remoteChildrenCount,
    required this.localMissionsCount,
    required this.remoteMissionsCount,
    required this.localRewardsCount,
    required this.remoteRewardsCount,
    required this.localMissionLogsCount,
    required this.remoteMissionLogsCount,
    required this.localRewardRequestsCount,
    required this.remoteRewardRequestsCount,
    required this.localStarBalance,
    required this.remoteDerivedBalance,
    required this.childBalanceDiagnostics,
    required this.warnings,
  });

  final int localChildrenCount;
  final int remoteChildrenCount;
  final int localMissionsCount;
  final int remoteMissionsCount;
  final int localRewardsCount;
  final int remoteRewardsCount;
  final int localMissionLogsCount;
  final int remoteMissionLogsCount;
  final int localRewardRequestsCount;
  final int remoteRewardRequestsCount;
  final int localStarBalance;
  final int remoteDerivedBalance;
  final List<ChildBalanceDiagnostic> childBalanceDiagnostics;
  final List<String> warnings;

  bool get hasDivergence {
    return localChildrenCount != remoteChildrenCount ||
        localMissionsCount != remoteMissionsCount ||
        localRewardsCount != remoteRewardsCount ||
        localMissionLogsCount != remoteMissionLogsCount ||
        localRewardRequestsCount != remoteRewardRequestsCount ||
        localStarBalance != remoteDerivedBalance ||
        childBalanceDiagnostics.any((item) => !item.isMatching) ||
        warnings.isNotEmpty;
  }

  bool get isAligned => !hasDivergence;
}

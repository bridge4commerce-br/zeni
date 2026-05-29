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

  bool get hasCatalogDivergence {
    return localChildrenCount != remoteChildrenCount ||
        localMissionsCount != remoteMissionsCount ||
        localRewardsCount != remoteRewardsCount;
  }

  bool get hasHistoricalDivergence {
    return localMissionLogsCount != remoteMissionLogsCount ||
        localRewardRequestsCount != remoteRewardRequestsCount;
  }

  bool get hasBalanceDivergence {
    return localStarBalance != remoteDerivedBalance ||
        childBalanceDiagnostics.any((item) => !item.isMatching);
  }

  bool get hasOnlyExpectedPartialRestoreDivergence {
    return !hasCatalogDivergence &&
        (hasHistoricalDivergence || hasBalanceDivergence) &&
        warnings.isEmpty;
  }

  bool get hasDivergence {
    return hasCatalogDivergence ||
        hasHistoricalDivergence ||
        hasBalanceDivergence ||
        warnings.isNotEmpty;
  }

  bool get isAligned => !hasDivergence;
}

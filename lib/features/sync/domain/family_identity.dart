import '../../../core/state/zeni_app_state.dart';

enum FamilyIdentityStatus {
  localUnboundSafe,
  bound,
  sessionMismatch,
  legacyUnboundWithData,
}

const familyIdentityBlockedMessage =
    'A família deste aparelho não está vinculada à família da sessão. '
    'Os dados locais foram preservados. Entre na conta correspondente ou '
    'use a recuperação em um aparelho vazio.';

/// Family.id is persisted by bootstrap; local_id belongs to domain entities,
/// not to the family. Authentication alone must never establish this binding.
class FamilyIdentity {
  const FamilyIdentity._();

  static bool isEmptySafe(ZeniAppState state) =>
      !state.hasUserContent &&
      state.missionLogs.isEmpty &&
      state.rewardRequests.isEmpty &&
      state.starLedgerEntries.isEmpty &&
      state.familyMembers.every((member) => member.childProfileId == null);

  static FamilyIdentityStatus evaluate(
    ZeniAppState state,
    String remoteFamilyId,
  ) {
    final localId = state.family.id;
    if (localId.isEmpty || localId == 'local-family') {
      return isEmptySafe(state)
          ? FamilyIdentityStatus.localUnboundSafe
          : FamilyIdentityStatus.legacyUnboundWithData;
    }
    if (remoteFamilyId.isEmpty || localId != remoteFamilyId) {
      return FamilyIdentityStatus.sessionMismatch;
    }
    final childIds = state.children.map((item) => item.id).toSet();
    final missionIds = state.missions.map((item) => item.id).toSet();
    final rewardIds = state.rewards.map((item) => item.id).toSet();
    final missionLogIds = state.missionLogs.map((item) => item.id).toSet();
    final rewardRequestIds = state.rewardRequests
        .map((item) => item.id)
        .toSet();
    final coherent =
        state.children.every((item) => item.familyId == localId) &&
        state.missions.every((item) => item.familyId == localId) &&
        state.rewards.every((item) => item.familyId == localId) &&
        state.starLedgerEntries.every((item) => item.familyId == localId) &&
        state.familyMembers.every((item) => item.familyId == localId) &&
        state.missionLogs.every(
          (item) =>
              childIds.contains(item.childId) &&
              missionIds.contains(item.missionId),
        ) &&
        state.rewardRequests.every(
          (item) =>
              childIds.contains(item.childId) &&
              rewardIds.contains(item.rewardId),
        ) &&
        state.starLedgerEntries.every(
          (item) =>
              childIds.contains(item.childId) &&
              (item.relatedMissionLogId == null ||
                  missionLogIds.contains(item.relatedMissionLogId)) &&
              (item.relatedRewardRequestId == null ||
                  rewardRequestIds.contains(item.relatedRewardRequestId)),
        );
    return coherent
        ? FamilyIdentityStatus.bound
        : FamilyIdentityStatus.legacyUnboundWithData;
  }
}

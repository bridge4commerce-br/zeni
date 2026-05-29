import '../../features/balance/data/models/star_ledger_entry.dart';
import '../../features/family/data/models/child_profile.dart';
import '../../features/family/data/models/family.dart';
import '../../features/family/data/models/family_member.dart';
import '../../features/rewards/data/models/reward.dart';
import '../../features/rewards/data/models/reward_request.dart';
import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/mission_log.dart';
import '../domain/zeni_enums.dart';

class ZeniMockData {
  const ZeniMockData._();

  static final DateTime _now = DateTime.now();

  static final Family family = Family(
    id: 'family-1',
    name: 'Família Silva',
    inviteCode: 'ZENI42',
    createdAt: _now.subtract(const Duration(days: 30)),
  );

  static final List<ChildProfile> children = [
    ChildProfile(
      id: 'child-1',
      familyId: family.id,
      name: 'Luna',
      emoji: '🦊',
      starBalance: 120,
      streakCount: 8,
      ttsEnabled: true,
      createdAt: _now.subtract(const Duration(days: 28)),
    ),
    ChildProfile(
      id: 'child-2',
      familyId: family.id,
      name: 'Theo',
      emoji: '🐼',
      starBalance: 75,
      streakCount: 4,
      createdAt: _now.subtract(const Duration(days: 22)),
    ),
  ];

  static final List<FamilyMember> members = [
    FamilyMember(
      id: 'member-1',
      familyId: family.id,
      name: 'Guilherme',
      email: 'responsavel@zeni.app',
      role: ZeniUserRole.parent,
      isOwner: true,
      createdAt: _now.subtract(const Duration(days: 30)),
    ),
    FamilyMember(
      id: 'member-2',
      familyId: family.id,
      name: 'Luna',
      role: ZeniUserRole.child,
      childProfileId: 'child-1',
      createdAt: _now.subtract(const Duration(days: 28)),
    ),
    FamilyMember(
      id: 'member-3',
      familyId: family.id,
      name: 'Theo',
      role: ZeniUserRole.child,
      childProfileId: 'child-2',
      createdAt: _now.subtract(const Duration(days: 22)),
    ),
  ];

  static final List<Mission> missions = [
    Mission(
      id: 'mission-1',
      familyId: family.id,
      childId: 'child-1',
      title: 'Arrumar a cama',
      description: 'Deixar a cama organizada antes da escola.',
      emoji: '🛏️',
      stars: 10,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.parentApproval,
      status: MissionStatus.active,
      createdAt: _now.subtract(const Duration(days: 20)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    Mission(
      id: 'mission-2',
      familyId: family.id,
      childId: 'child-1',
      title: 'Escovar os dentes',
      description: 'Escovar os dentes depois do café e antes de dormir.',
      emoji: '🪥',
      stars: 5,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.anytime,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: _now.subtract(const Duration(days: 18)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    Mission(
      id: 'mission-3',
      familyId: family.id,
      childId: 'child-1',
      title: 'Ler 10 minutos',
      description: 'Escolher um livro e ler por pelo menos 10 minutos.',
      emoji: '📚',
      stars: 15,
      recurrence: MissionRecurrence.weekdays,
      timeGroup: MissionTimeGroup.evening,
      approvalMode: MissionApprovalMode.parentApproval,
      status: MissionStatus.active,
      createdAt: _now.subtract(const Duration(days: 15)),
      updatedAt: _now.subtract(const Duration(days: 1)),
      requiresPhoto: true,
    ),
    Mission(
      id: 'mission-4',
      familyId: family.id,
      childId: 'child-2',
      title: 'Guardar brinquedos',
      description: 'Guardar os brinquedos antes do jantar.',
      emoji: '🧸',
      stars: 10,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.evening,
      approvalMode: MissionApprovalMode.parentApproval,
      status: MissionStatus.active,
      createdAt: _now.subtract(const Duration(days: 10)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
  ];

  static final List<MissionLog> missionLogs = [
    MissionLog(
      id: 'log-1',
      missionId: 'mission-1',
      childId: 'child-1',
      scheduledDate: DateTime(_now.year, _now.month, _now.day),
      status: MissionLogStatus.pending,
      starsAwarded: 10,
    ),
    MissionLog(
      id: 'log-2',
      missionId: 'mission-2',
      childId: 'child-1',
      scheduledDate: DateTime(_now.year, _now.month, _now.day),
      status: MissionLogStatus.approved,
      completedAt: _now.subtract(const Duration(hours: 2)),
      approvedAt: _now.subtract(const Duration(hours: 2)),
      starsAwarded: 5,
    ),
    MissionLog(
      id: 'log-3',
      missionId: 'mission-3',
      childId: 'child-1',
      scheduledDate: DateTime(_now.year, _now.month, _now.day),
      status: MissionLogStatus.awaitingApproval,
      completedAt: _now.subtract(const Duration(minutes: 35)),
      note: 'Li o livro do dinossauro.',
      starsAwarded: 15,
    ),
    MissionLog(
      id: 'log-4',
      missionId: 'mission-4',
      childId: 'child-2',
      scheduledDate: DateTime(_now.year, _now.month, _now.day),
      status: MissionLogStatus.pending,
      starsAwarded: 10,
    ),
  ];

  static final List<Reward> rewards = [
    Reward(
      id: 'reward-1',
      familyId: family.id,
      title: 'Escolher o filme',
      description: 'Escolher o filme da noite em família.',
      emoji: '🎬',
      cost: 40,
      renewal: RewardRenewal.weekly,
      createdAt: _now.subtract(const Duration(days: 18)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    Reward(
      id: 'reward-2',
      familyId: family.id,
      title: 'Sorvete no fim de semana',
      description: 'Tomar um sorvete especial no sábado ou domingo.',
      emoji: '🍦',
      cost: 80,
      renewal: RewardRenewal.weekly,
      createdAt: _now.subtract(const Duration(days: 16)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    Reward(
      id: 'reward-3',
      familyId: family.id,
      title: '30 minutos de videogame',
      description: 'Tempo extra de diversão depois das missões.',
      emoji: '🎮',
      cost: 60,
      renewal: RewardRenewal.daily,
      createdAt: _now.subtract(const Duration(days: 12)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
  ];

  static final List<RewardRequest> rewardRequests = [
    RewardRequest(
      id: 'request-1',
      rewardId: 'reward-1',
      childId: 'child-1',
      status: RewardRequestStatus.pending,
      requestedAt: _now.subtract(const Duration(hours: 5)),
      note: 'Quero escolher o filme hoje.',
    ),
  ];

  static final List<StarLedgerEntry> ledgerEntries = [
    StarLedgerEntry(
      id: 'ledger-1',
      familyId: family.id,
      childId: 'child-1',
      amount: 10,
      balanceAfter: 120,
      type: StarLedgerEntryType.earned,
      title: 'Arrumar a cama',
      description: 'Missão aprovada pelo responsável.',
      createdAt: _now.subtract(const Duration(days: 1, hours: 2)),
      relatedMissionLogId: 'log-old-1',
    ),
    StarLedgerEntry(
      id: 'ledger-2',
      familyId: family.id,
      childId: 'child-1',
      amount: -40,
      balanceAfter: 110,
      type: StarLedgerEntryType.spent,
      title: 'Escolher o filme',
      description: 'Mimo resgatado.',
      createdAt: _now.subtract(const Duration(days: 2, hours: 4)),
      relatedRewardRequestId: 'request-old-1',
    ),
    StarLedgerEntry(
      id: 'ledger-3',
      familyId: family.id,
      childId: 'child-1',
      amount: 15,
      balanceAfter: 150,
      type: StarLedgerEntryType.earned,
      title: 'Ler 10 minutos',
      description: 'Sequência mantida.',
      createdAt: _now.subtract(const Duration(days: 3, hours: 3)),
      relatedMissionLogId: 'log-old-2',
    ),
  ];
}

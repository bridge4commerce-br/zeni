enum ZeniUserRole { parent, child }

extension ZeniUserRoleX on ZeniUserRole {
  String get label {
    return switch (this) {
      ZeniUserRole.parent => 'Responsável',
      ZeniUserRole.child => 'Criança',
    };
  }
}

enum MissionRecurrence { once, daily, weekdays, weekends, customDaysOfWeek }

extension MissionRecurrenceX on MissionRecurrence {
  String get label {
    return switch (this) {
      MissionRecurrence.once => 'Uma vez',
      MissionRecurrence.daily => 'Todos os dias',
      MissionRecurrence.weekdays => 'Dias de semana',
      MissionRecurrence.weekends => 'Finais de semana',
      MissionRecurrence.customDaysOfWeek => 'Dias personalizados',
    };
  }

  String get storageValue {
    return switch (this) {
      MissionRecurrence.customDaysOfWeek => 'customDaysOfWeek',
      _ => name,
    };
  }
}

MissionRecurrence missionRecurrenceFromStorage(String? value) {
  return switch (value) {
    'once' => MissionRecurrence.once,
    'daily' => MissionRecurrence.daily,
    'weekdays' => MissionRecurrence.weekdays,
    'weekends' => MissionRecurrence.weekends,
    'custom' || 'customDaysOfWeek' => MissionRecurrence.customDaysOfWeek,
    _ => MissionRecurrence.daily,
  };
}

enum MissionTimeGroup { morning, afternoon, evening, anytime }

extension MissionTimeGroupX on MissionTimeGroup {
  String get label {
    return switch (this) {
      MissionTimeGroup.morning => 'Manhã',
      MissionTimeGroup.afternoon => 'Tarde',
      MissionTimeGroup.evening => 'Noite',
      MissionTimeGroup.anytime => 'Qualquer horário',
    };
  }

  String get emoji {
    return switch (this) {
      MissionTimeGroup.morning => '☀️',
      MissionTimeGroup.afternoon => '🌤️',
      MissionTimeGroup.evening => '🌙',
      MissionTimeGroup.anytime => '⭐',
    };
  }
}

enum MissionApprovalMode { automatic, parentApproval }

extension MissionApprovalModeX on MissionApprovalMode {
  String get label {
    return switch (this) {
      MissionApprovalMode.automatic => 'Aprovação automática',
      MissionApprovalMode.parentApproval => 'Aprovação do responsável',
    };
  }
}

enum MissionStatus { active, paused, archived }

extension MissionStatusX on MissionStatus {
  String get label {
    return switch (this) {
      MissionStatus.active => 'Ativa',
      MissionStatus.paused => 'Pausada',
      MissionStatus.archived => 'Arquivada',
    };
  }
}

enum MissionLogStatus { pending, awaitingApproval, approved, rejected, skipped }

extension MissionLogStatusX on MissionLogStatus {
  String get label {
    return switch (this) {
      MissionLogStatus.pending => 'Pendente',
      MissionLogStatus.awaitingApproval => 'Aguardando aprovação',
      MissionLogStatus.approved => 'Concluída',
      MissionLogStatus.rejected => 'Rejeitada',
      MissionLogStatus.skipped => 'Pulada',
    };
  }
}

enum RewardRenewal { once, daily, weekly, monthly, always }

extension RewardRenewalX on RewardRenewal {
  String get label {
    return switch (this) {
      RewardRenewal.once => 'Uma vez',
      RewardRenewal.daily => 'Diário',
      RewardRenewal.weekly => 'Semanal',
      RewardRenewal.monthly => 'Mensal',
      RewardRenewal.always => 'Sempre disponível',
    };
  }
}

enum RewardRequestStatus { pending, approved, rejected, delivered, cancelled }

extension RewardRequestStatusX on RewardRequestStatus {
  String get label {
    return switch (this) {
      RewardRequestStatus.pending => 'Pendente',
      RewardRequestStatus.approved => 'Aprovado',
      RewardRequestStatus.rejected => 'Rejeitado',
      RewardRequestStatus.delivered => 'Entregue',
      RewardRequestStatus.cancelled => 'Cancelado',
    };
  }
}

enum StarLedgerEntryType { earned, spent, refunded, adjusted }

extension StarLedgerEntryTypeX on StarLedgerEntryType {
  String get label {
    return switch (this) {
      StarLedgerEntryType.earned => 'Ganho',
      StarLedgerEntryType.spent => 'Gasto',
      StarLedgerEntryType.refunded => 'Devolvido',
      StarLedgerEntryType.adjusted => 'Ajuste',
    };
  }
}

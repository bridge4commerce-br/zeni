import '../../../core/domain/zeni_enums.dart';
import '../../rewards/data/models/reward.dart';
import '../../rewards/data/models/reward_request.dart';
import '../../tasks/data/models/mission.dart';
import '../../tasks/data/models/mission_log.dart';
import 'zeni_speech_text_sanitizer.dart';

class ZeniMissionSpeechTextBuilder {
  const ZeniMissionSpeechTextBuilder._();

  static String buildMissionShortSpeech(Mission mission) {
    final description =
        ZeniSpeechTextSanitizer.sanitizeMissionDescriptionForSpeech(
          mission.description,
        );

    return _joinSentences(<String>['Missão: ${mission.title}', ?description]);
  }

  static String buildMissionDetailsSpeech({
    required Mission mission,
    MissionLog? log,
  }) {
    final status = log?.status ?? MissionLogStatus.pending;

    return _joinSentences(<String>[
      'Missão: ${mission.title}',
      _friendlyMissionStatus(status),
      'Vale ${mission.stars} estrelas',
      'Pode ser feita ${_friendlyMissionTimeGroup(mission.timeGroup)}',
      _friendlyApprovalMode(mission.approvalMode),
    ]);
  }

  static String _friendlyMissionStatus(MissionLogStatus status) {
    return switch (status) {
      MissionLogStatus.pending => 'ainda falta concluir',
      MissionLogStatus.awaitingApproval => 'esperando aprovação do responsável',
      MissionLogStatus.approved => 'já foi concluída',
      MissionLogStatus.rejected => 'precisa tentar de novo',
      MissionLogStatus.skipped => 'ficou para outro momento',
    };
  }

  static String _friendlyMissionTimeGroup(MissionTimeGroup timeGroup) {
    return switch (timeGroup) {
      MissionTimeGroup.morning => 'de manhã',
      MissionTimeGroup.afternoon => 'a tarde',
      MissionTimeGroup.evening => 'à noite',
      MissionTimeGroup.anytime => 'em qualquer horário do dia',
    };
  }

  static String _friendlyApprovalMode(MissionApprovalMode approvalMode) {
    return switch (approvalMode) {
      MissionApprovalMode.parentApproval =>
        'Depois que você enviar, um responsável precisa aprovar',
      MissionApprovalMode.automatic => 'As estrelas entram na hora',
    };
  }
}

class ZeniRewardSpeechTextBuilder {
  const ZeniRewardSpeechTextBuilder._();

  static String buildRewardShortSpeech(Reward reward) {
    final description =
        ZeniSpeechTextSanitizer.sanitizeRewardDescriptionForSpeech(
          reward.description,
        );

    return _joinSentences(<String>['Mimo: ${reward.title}', ?description]);
  }

  static String buildRewardDetailsSpeech({
    required Reward reward,
    required int childBalance,
    RewardRequest? request,
  }) {
    final missingStars = reward.cost - childBalance;

    return _joinSentences(<String>[
      'Mimo: ${reward.title}',
      'Custa ${reward.cost} estrelas',
      _friendlyRewardStatus(
        reward: reward,
        childBalance: childBalance,
        missingStars: missingStars,
        request: request,
      ),
      _friendlyRewardApproval(request),
    ]);
  }

  static String _friendlyRewardStatus({
    required Reward reward,
    required int childBalance,
    required int missingStars,
    RewardRequest? request,
  }) {
    if (request != null) {
      return switch (request.status) {
        RewardRequestStatus.pending =>
          'Seu pedido está esperando o responsável',
        RewardRequestStatus.approved => 'Seu pedido já foi aprovado',
        RewardRequestStatus.rejected =>
          'Este pedido precisa ser tentado de novo',
        RewardRequestStatus.delivered => 'Seu mimo já foi entregue',
        RewardRequestStatus.cancelled => 'Este pedido foi cancelado',
      };
    }

    if (childBalance >= reward.cost) {
      return 'Você já pode pedir este mimo';
    }

    return 'Faltam $missingStars estrelas para pedir este mimo';
  }

  static String _friendlyRewardApproval(RewardRequest? request) {
    if (request?.status == RewardRequestStatus.pending) {
      return 'Agora é só aguardar o responsável';
    }

    return 'Quando você pedir, depois é só aguardar o responsável';
  }
}

String _joinSentences(List<String> parts) {
  return parts
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join('. ');
}

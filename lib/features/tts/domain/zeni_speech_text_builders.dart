import '../../../core/domain/zeni_enums.dart';
import '../../rewards/data/models/reward.dart';
import '../../rewards/data/models/reward_request.dart';
import '../../tasks/data/models/mission.dart';
import '../../tasks/data/models/mission_log.dart';
import 'zeni_speech_text_sanitizer.dart';
import 'zeni_tts_voice_selector.dart';

class ZeniMissionSpeechTextBuilder {
  const ZeniMissionSpeechTextBuilder._();

  static String buildMissionShortSpeech({
    required Mission mission,
    required String locale,
  }) {
    final description =
        ZeniSpeechTextSanitizer.sanitizeMissionDescriptionForSpeech(
          mission.description,
        );
    final templates = _MissionSpeechTemplates.forLocale(locale);
    if (templates == null) {
      return _joinSentences(<String>[mission.title, ?description]);
    }
    return _joinSentences(<String>[
      templates.introduction(_sentenceFragment(mission.title)),
      ?description,
    ]);
  }

  static String buildMissionDetailsSpeech({
    required Mission mission,
    required String locale,
    MissionLog? log,
  }) {
    final status = log?.status ?? MissionLogStatus.pending;
    final description =
        ZeniSpeechTextSanitizer.sanitizeMissionDescriptionForSpeech(
          mission.description,
        );
    final templates = _MissionSpeechTemplates.forLocale(locale);
    if (templates == null) {
      return _joinSentences(<String>[mission.title, ?description]);
    }

    return _joinSentences(<String>[
      templates.introduction(_sentenceFragment(mission.title)),
      ?description,
      templates.status(status),
      templates.reward(mission.stars, mission.approvalMode),
      ?templates.time(mission.timeGroup),
      ?templates.approval(mission.approvalMode),
    ]);
  }

  static String _sentenceFragment(String value) {
    return value.trim().replaceFirst(RegExp(r'[.!?。]+$'), '');
  }
}

class _MissionSpeechTemplates {
  const _MissionSpeechTemplates._(this.language);

  final String language;

  static _MissionSpeechTemplates? forLocale(String locale) {
    final language = ZeniTtsLocale.languageCode(locale);
    return switch (language) {
      'pt' ||
      'en' ||
      'es' ||
      'de' ||
      'ja' => _MissionSpeechTemplates._(language),
      _ => null,
    };
  }

  String introduction(String title) {
    return switch (language) {
      'pt' => 'Sua missão é $title',
      'en' => 'Your mission is $title',
      'es' => 'Tu misión es $title',
      'de' => 'Deine Aufgabe ist $title',
      'ja' => 'きょうのミッションは$titleです',
      _ => title,
    };
  }

  String status(MissionLogStatus status) {
    return switch (language) {
      'pt' => switch (status) {
        MissionLogStatus.pending => 'Ainda falta concluir',
        MissionLogStatus.awaitingApproval =>
          'Essa missão já foi enviada e está esperando a aprovação do responsável',
        MissionLogStatus.approved => 'Você já concluiu essa missão hoje',
        MissionLogStatus.rejected =>
          'O responsável pediu para você tentar essa missão de novo',
        MissionLogStatus.skipped => 'Essa missão ficou para outro momento',
      },
      'en' => switch (status) {
        MissionLogStatus.pending => 'You still need to finish this mission',
        MissionLogStatus.awaitingApproval =>
          'This mission is waiting for your grown-up to approve it',
        MissionLogStatus.approved => 'You already finished this mission today',
        MissionLogStatus.rejected => 'Your grown-up asked you to try again',
        MissionLogStatus.skipped => 'This mission can wait for another time',
      },
      'es' => switch (status) {
        MissionLogStatus.pending => 'Todavía falta terminar esta misión',
        MissionLogStatus.awaitingApproval =>
          'Esta misión está esperando la aprobación de una persona adulta',
        MissionLogStatus.approved => 'Ya terminaste esta misión hoy',
        MissionLogStatus.rejected =>
          'Una persona adulta te pidió que lo intentes de nuevo',
        MissionLogStatus.skipped =>
          'Esta misión puede esperar para otro momento',
      },
      'de' => switch (status) {
        MissionLogStatus.pending => 'Diese Aufgabe musst du noch erledigen',
        MissionLogStatus.awaitingApproval =>
          'Diese Aufgabe wartet auf die Bestätigung einer erwachsenen Person',
        MissionLogStatus.approved =>
          'Du hast diese Aufgabe heute schon erledigt',
        MissionLogStatus.rejected =>
          'Eine erwachsene Person hat dich gebeten, es noch einmal zu versuchen',
        MissionLogStatus.skipped => 'Diese Aufgabe kann auf später warten',
      },
      'ja' => switch (status) {
        MissionLogStatus.pending => 'このミッションはまだ終わっていません',
        MissionLogStatus.awaitingApproval => 'このミッションはおうちの人の確認を待っています',
        MissionLogStatus.approved => 'このミッションは今日もう終わっています',
        MissionLogStatus.rejected => 'おうちの人がもう一度やってみてと言っています',
        MissionLogStatus.skipped => 'このミッションはあとでやっても大丈夫です',
      },
      _ => '',
    };
  }

  String reward(int stars, MissionApprovalMode approvalMode) {
    final starText = switch (language) {
      'pt' => '$stars ${stars == 1 ? 'estrela' : 'estrelas'}',
      'en' => '$stars ${stars == 1 ? 'star' : 'stars'}',
      'es' => '$stars ${stars == 1 ? 'estrella' : 'estrellas'}',
      'de' => '$stars ${stars == 1 ? 'Stern' : 'Sterne'}',
      'ja' => '$stars 個の星',
      _ => '$stars',
    };
    final needsApproval = approvalMode == MissionApprovalMode.parentApproval;
    return switch (language) {
      'pt' =>
        needsApproval
            ? 'Quando terminar, você pode ganhar $starText'
            : 'Quando terminar, você ganha $starText',
      'en' =>
        needsApproval
            ? 'When you finish, you can earn $starText'
            : 'When you finish, you earn $starText',
      'es' =>
        needsApproval
            ? 'Cuando termines, puedes ganar $starText'
            : 'Cuando termines, ganas $starText',
      'de' =>
        needsApproval
            ? 'Wenn du fertig bist, kannst du $starText bekommen'
            : 'Wenn du fertig bist, bekommst du $starText',
      'ja' =>
        needsApproval ? '終わったら、$starTextをもらえるかもしれません' : '終わったら、$starTextをもらえます',
      _ => '',
    };
  }

  String? time(MissionTimeGroup timeGroup) {
    if (timeGroup == MissionTimeGroup.anytime) return null;
    return switch (language) {
      'pt' => switch (timeGroup) {
        MissionTimeGroup.morning => 'Você pode fazer essa missão de manhã',
        MissionTimeGroup.afternoon => 'Você pode fazer essa missão à tarde',
        MissionTimeGroup.evening => 'Você pode fazer essa missão à noite',
        MissionTimeGroup.anytime => null,
      },
      'en' => switch (timeGroup) {
        MissionTimeGroup.morning => 'You can do this mission in the morning',
        MissionTimeGroup.afternoon =>
          'You can do this mission in the afternoon',
        MissionTimeGroup.evening => 'You can do this mission in the evening',
        MissionTimeGroup.anytime => null,
      },
      'es' => switch (timeGroup) {
        MissionTimeGroup.morning => 'Puedes hacer esta misión por la mañana',
        MissionTimeGroup.afternoon => 'Puedes hacer esta misión por la tarde',
        MissionTimeGroup.evening => 'Puedes hacer esta misión por la noche',
        MissionTimeGroup.anytime => null,
      },
      'de' => switch (timeGroup) {
        MissionTimeGroup.morning => 'Du kannst diese Aufgabe am Morgen machen',
        MissionTimeGroup.afternoon =>
          'Du kannst diese Aufgabe am Nachmittag machen',
        MissionTimeGroup.evening => 'Du kannst diese Aufgabe am Abend machen',
        MissionTimeGroup.anytime => null,
      },
      'ja' => switch (timeGroup) {
        MissionTimeGroup.morning => 'このミッションは朝にできます',
        MissionTimeGroup.afternoon => 'このミッションは午後にできます',
        MissionTimeGroup.evening => 'このミッションは夜にできます',
        MissionTimeGroup.anytime => null,
      },
      _ => null,
    };
  }

  String? approval(MissionApprovalMode approvalMode) {
    if (approvalMode == MissionApprovalMode.automatic) return null;
    return switch (language) {
      'pt' => 'Depois, é só esperar a aprovação do responsável',
      'en' => 'Then, wait for your grown-up to approve it',
      'es' => 'Después, solo espera la aprobación de una persona adulta',
      'de' => 'Danach wartest du auf die Bestätigung einer erwachsenen Person',
      'ja' => 'そのあと、おうちの人の確認を待ちましょう',
      _ => null,
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
      .map((part) => RegExp(r'[.!?]$').hasMatch(part) ? part : '$part.')
      .join(' ');
}

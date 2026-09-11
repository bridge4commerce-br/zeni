import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';
import 'package:zeni/features/tts/domain/zeni_speech_text_builders.dart';

void main() {
  Mission mission({
    int stars = 2,
    MissionApprovalMode approvalMode = MissionApprovalMode.automatic,
    String description = 'Put everything back in its place.',
  }) {
    return Mission(
      id: 'mission-1',
      familyId: 'family-1',
      childId: 'child-1',
      title: 'Put away my things',
      description: description,
      stars: stars,
      recurrence: MissionRecurrence.daily,
      timeGroup: MissionTimeGroup.anytime,
      approvalMode: approvalMode,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  test('Portuguese handles automatic, approval, singular and plural stars', () {
    final automatic = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(stars: 1),
      locale: 'pt-BR',
    );
    final approval = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(
        stars: 2,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
      locale: 'pt',
    );

    expect(automatic, contains('Sua missão é'));
    expect(automatic, contains('1 estrela'));
    expect(approval, contains('2 estrelas'));
    expect(approval, contains('pode ganhar'));
    expect(approval, contains('aprovação do responsável'));
  });

  test('English templates normalize regional locales and pluralize stars', () {
    final automatic = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(stars: 1),
      locale: 'en-US',
    );
    final approval = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(
        stars: 3,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
      locale: 'en-GB',
    );

    expect(automatic, contains('Your mission is'));
    expect(automatic, contains('1 star'));
    expect(approval, contains('3 stars'));
    expect(approval, contains('wait for your grown-up'));
  });

  test('Spanish and German templates use friendly approval language', () {
    final spanish = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(approvalMode: MissionApprovalMode.parentApproval),
      locale: 'es-MX',
    );
    final german = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(approvalMode: MissionApprovalMode.parentApproval),
      locale: 'de-DE',
    );

    expect(spanish, contains('Tu misión es'));
    expect(spanish, contains('persona adulta'));
    expect(german, contains('Deine Aufgabe ist'));
    expect(german, contains('erwachsenen Person'));
  });

  test('Japanese uses its own sentence order for rewards and approval', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(
        stars: 2,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
      locale: 'ja-JP',
    );

    expect(speech, contains('きょうのミッションは'));
    expect(speech, contains('2 個の星をもらえるかもしれません'));
    expect(speech, contains('おうちの人の確認を待ちましょう'));
  });

  test('unknown locales keep only dynamic title and description', () {
    final speech = ZeniMissionSpeechTextBuilder.buildMissionDetailsSpeech(
      mission: mission(),
      locale: 'ko-KR',
    );

    expect(speech, 'Put away my things. Put everything back in its place.');
    expect(speech, isNot(contains('Sua missão')));
    expect(speech, isNot(contains('Your mission')));
    expect(speech, isNot(contains('estrelas')));
  });
}

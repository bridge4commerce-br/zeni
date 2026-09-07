import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/smart_content/data/repositories/asset_smart_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetSmartContentRepository', () {
    late AssetSmartContentRepository repository;

    setUp(() {
      repository = AssetSmartContentRepository();
    });

    test('carrega as 94 missões reais', () async {
      final missions = await repository.getMissions('pt-BR');

      expect(missions, hasLength(94));
      expect(missions.map((mission) => mission.id).toSet(), hasLength(94));
      expect(missions.first.id, 'brush_teeth');
      expect(missions.first.title, 'Escovar os dentes');
    });

    test('carrega as 26 rotinas reais', () async {
      final routines = await repository.getRoutines('pt-BR');

      expect(routines, hasLength(26));
      expect(routines.map((routine) => routine.id).toSet(), hasLength(26));
      expect(routines.first.id, 'after_school');
      expect(routines.first.title, 'Cheguei em casa');
    });

    test('resolve locale regional para idioma suportado', () async {
      final regional = await repository.getMissions('en-US');
      final base = await repository.getMissions('en');

      expect(regional, hasLength(94));
      expect(
        regional.map((mission) => mission.title).toList(),
        base.map((mission) => mission.title).toList(),
      );
    });

    test('usa pt-BR como fallback para locale não suportado', () async {
      final unsupported = await repository.getMissions('it-IT');
      final fallback = await repository.getMissions('pt-BR');

      expect(
        unsupported.map((mission) => mission.title).toList(),
        fallback.map((mission) => mission.title).toList(),
      );
    });

    test(
      'todas as etapas das rotinas apontam para missões existentes',
      () async {
        final missions = await repository.getMissions('pt-BR');
        final routines = await repository.getRoutines('pt-BR');

        final missionIds = missions.map((mission) => mission.id).toSet();

        for (final routine in routines) {
          for (final stepId in routine.steps) {
            expect(
              missionIds,
              contains(stepId),
              reason:
                  'A rotina ${routine.id} referencia uma missão inexistente: '
                  '$stepId',
            );
          }
        }
      },
    );
  });
}

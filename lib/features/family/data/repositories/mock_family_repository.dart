import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../models/child_profile.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import 'family_repository.dart';

class MockFamilyRepository implements FamilyRepository {
  MockFamilyRepository(this._ref);

  final Ref _ref;

  @override
  Future<Family> getCurrentFamily() async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).family;
  }

  @override
  Future<List<ChildProfile>> getChildren({bool includeArchived = false}) async {
    final children = (await _ref.read(
      zeniAppStateControllerProvider.future,
    )).children;
    if (includeArchived) {
      return children;
    }

    return children.where((child) => child.isActive).toList();
  }

  @override
  Future<ChildProfile?> getChildById(String childId) async {
    return (await _ref.read(
      zeniAppStateControllerProvider.future,
    )).childById(childId);
  }

  @override
  Future<List<FamilyMember>> getMembers() async {
    return (await _ref.read(
      zeniAppStateControllerProvider.future,
    )).familyMembers;
  }

  @override
  Future<ChildProfile> createChild({
    required String familyId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .createChild(
          familyId: familyId,
          name: name,
          emoji: emoji,
          birthDate: birthDate,
        );
  }

  @override
  Future<ChildProfile?> updateChild({
    required String childId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateChild(
          childId: childId,
          name: name,
          emoji: emoji,
          birthDate: birthDate,
        );
  }

  @override
  Future<void> archiveChild(String childId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .setChildArchived(childId: childId, isActive: false);
  }

  @override
  Future<void> restoreChild(String childId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .setChildArchived(childId: childId, isActive: true);
  }
}

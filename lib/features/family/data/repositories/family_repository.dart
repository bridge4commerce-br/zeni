import '../models/child_profile.dart';
import '../models/family.dart';
import '../models/family_member.dart';

abstract class FamilyRepository {
  Future<Family> getCurrentFamily();

  Future<List<ChildProfile>> getChildren({bool includeArchived = false});

  Future<ChildProfile?> getChildById(String childId);

  Future<List<FamilyMember>> getMembers();

  Future<ChildProfile> createChild({
    required String familyId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  });

  Future<ChildProfile?> updateChild({
    required String childId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  });

  Future<void> archiveChild(String childId);

  Future<void> restoreChild(String childId);
}

class ZeniChildAvatar {
  const ZeniChildAvatar({required this.id, required this.assetPath});
  final String id;
  final String assetPath;
}

class ZeniChildAvatarCatalog {
  const ZeniChildAvatarCatalog._();
  static const fallbackId = 'zeni_avatar_green';
  static const all = [
    ZeniChildAvatar(
      id: 'zeni_avatar_green',
      assetPath: 'assets/avatars/zeni_avatar_green.png',
    ),
    ZeniChildAvatar(
      id: 'zeni_avatar_blue',
      assetPath: 'assets/avatars/zeni_avatar_blue.png',
    ),
    ZeniChildAvatar(
      id: 'zeni_avatar_violet',
      assetPath: 'assets/avatars/zeni_avatar_violet.png',
    ),
    ZeniChildAvatar(
      id: 'zeni_avatar_coral',
      assetPath: 'assets/avatars/zeni_avatar_coral.png',
    ),
  ];
  static ZeniChildAvatar byId(String? id) {
    for (final avatar in all) {
      if (avatar.id == id) return avatar;
    }
    return all.firstWhere((avatar) => avatar.id == fallbackId);
  }

  static String legacyToId(String? legacy) => switch (legacy) {
    '🐼' => 'zeni_avatar_blue',
    '🦁' => 'zeni_avatar_coral',
    '🐨' => 'zeni_avatar_violet',
    _ => fallbackId,
  };
}

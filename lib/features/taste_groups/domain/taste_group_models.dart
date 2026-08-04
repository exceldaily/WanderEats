/// One row of `taste_groups_list()`.
class TasteGroup {
  const TasteGroup({
    required this.id,
    required this.name,
    this.description,
    this.emoji,
    required this.creatorId,
    required this.creatorUsername,
    this.memberCount = 0,
    this.pickCount = 0,
    this.isMember = false,
    this.isOwner = false,
  });

  factory TasteGroup.fromRow(Map<String, dynamic> row) => TasteGroup(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    description: row['description'] as String?,
    emoji: row['emoji'] as String?,
    creatorId: row['creator_id'] as String,
    creatorUsername: row['creator_username'] as String? ?? '',
    memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
    pickCount: (row['pick_count'] as num?)?.toInt() ?? 0,
    isMember: row['is_member'] == true,
    isOwner: row['my_role'] == 'owner',
  );

  final String id;
  final String name;
  final String? description;
  final String? emoji;
  final String creatorId;
  final String creatorUsername;
  final int memberCount;
  final int pickCount;
  final bool isMember;
  final bool isOwner;
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isOwner = false,
  });

  factory GroupMember.fromRow(Map<String, dynamic> row) {
    final p = (row['profiles'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GroupMember(
      userId: p['id'] as String? ?? '',
      username: p['username'] as String? ?? '',
      displayName: p['display_name'] as String? ?? '',
      avatarUrl: p['avatar_url'] as String?,
      isOwner: row['role'] == 'owner',
    );
  }

  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isOwner;
}

class GroupPick {
  const GroupPick({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.coverPhotoUrl,
    this.note,
    required this.addedBy,
  });

  factory GroupPick.fromRow(Map<String, dynamic> row) {
    final r = (row['restaurants'] as Map?)?.cast<String, dynamic>() ?? const {};
    return GroupPick(
      id: row['id'] as String,
      restaurantId: r['id'] as String? ?? '',
      restaurantName: r['name'] as String? ?? '',
      coverPhotoUrl: r['cover_photo_url'] as String?,
      note: row['note'] as String?,
      addedBy: row['added_by'] as String? ?? '',
    );
  }

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? coverPhotoUrl;
  final String? note;
  final String addedBy;
}

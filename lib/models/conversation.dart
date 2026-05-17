class ConversationMember {
  final String userId;
  final String? userName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const ConversationMember({
    required this.userId,
    this.userName,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      ConversationMember(
        userId: json['user_id'] as String,
        userName: json['user_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        joinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : DateTime.now(),
      );
}

class Conversation {
  final String id;
  final String? name;
  final String type; // 'direct' or 'group'
  final String? skillId;
  final String createdBy;
  final DateTime createdAt;
  final List<ConversationMember> members;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    this.name,
    required this.type,
    this.skillId,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final membersJson = json['conversation_members'] as List<dynamic>?;
    return Conversation(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: json['type'] as String? ?? 'direct',
      skillId: json['skill_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: membersJson
              ?.map((m) =>
                  ConversationMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
    );
  }

  String displayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) return name!;
    if (type == 'direct' && members.isNotEmpty) {
      final other = members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => members.first,
      );
      return other.userName ?? 'Chat';
    }
    return 'Gruppe';
  }

  String? otherAvatar(String currentUserId) {
    if (type == 'direct' && members.isNotEmpty) {
      try {
        return members
            .firstWhere((m) => m.userId != currentUserId)
            .avatarUrl;
      } catch (_) {}
    }
    return null;
  }

  Conversation copyWith({
    List<ConversationMember>? members,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) =>
      Conversation(
        id: id,
        name: name,
        type: type,
        skillId: skillId,
        createdBy: createdBy,
        createdAt: createdAt,
        members: members ?? this.members,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      );
}

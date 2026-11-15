enum ConversationType { direct, group }

class ConversationMember {
  const ConversationMember({
    required this.userId,
    this.userName,
    this.avatarUrl,
  });

  final String userId;
  final String? userName;
  final String? avatarUrl;

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      ConversationMember(
        userId: json['user_id'] as String,
        userName: json['user_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.createdAt,
    this.name,
    this.members = const [],
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final String? name;
  final ConversationType type;
  final DateTime createdAt;
  final List<ConversationMember> members;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  bool get isGroup => type == ConversationType.group;
  DateTime get sortKey => lastMessageAt ?? createdAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final members = (json['conversation_members'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ConversationMember.fromJson)
        .toList();

    return Conversation(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: json['type'] == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: members,
      lastMessage: json['last_message'] as String?,
      lastMessageAt:
          DateTime.tryParse(json['last_message_at'] as String? ?? ''),
    );
  }

  ConversationMember? partnerOf(String userId) {
    if (isGroup) return null;
    for (final m in members) {
      if (m.userId != userId) return m;
    }
    return null;
  }

  bool hasMember(String userId) => members.any((m) => m.userId == userId);

  String titleFor(String userId) {
    if (name?.isNotEmpty ?? false) return name!;
    if (isGroup) return 'Gruppe';
    return partnerOf(userId)?.userName ?? 'Chat';
  }

  Conversation withLastMessage(String text, DateTime at) => Conversation(
        id: id,
        name: name,
        type: type,
        createdAt: createdAt,
        members: members,
        lastMessage: text,
        lastMessageAt: at,
      );
}

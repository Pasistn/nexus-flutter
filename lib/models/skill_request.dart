class SkillRequest {
  final String id;
  final String skillId;
  final String? skillTitle;
  final String requesterId;
  final String? requesterName;
  final String? requesterAvatar;
  final String skillOwnerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? message;
  final DateTime createdAt;

  const SkillRequest({
    required this.id,
    required this.skillId,
    this.skillTitle,
    required this.requesterId,
    this.requesterName,
    this.requesterAvatar,
    required this.skillOwnerId,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory SkillRequest.fromJson(Map<String, dynamic> json) => SkillRequest(
        id: json['id'] as String,
        skillId: json['skill_id'] as String,
        skillTitle: json['skill_title'] as String?,
        requesterId: json['requester_id'] as String,
        requesterName: json['requester_name'] as String?,
        requesterAvatar: json['requester_avatar'] as String?,
        skillOwnerId: json['skill_owner_id'] as String,
        status: json['status'] as String? ?? 'pending',
        message: json['message'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

enum RequestStatus { pending, accepted, rejected }

class SkillRequest {
  const SkillRequest({
    required this.id,
    required this.skillId,
    required this.requesterId,
    required this.skillOwnerId,
    required this.status,
    required this.createdAt,
    this.skillTitle,
    this.requesterName,
    this.requesterAvatar,
    this.message,
  });

  final String id;
  final String skillId;
  final String? skillTitle;
  final String requesterId;
  final String? requesterName;
  final String? requesterAvatar;
  final String skillOwnerId;
  final RequestStatus status;
  final String? message;
  final DateTime createdAt;

  bool get isPending => status == RequestStatus.pending;

  factory SkillRequest.fromJson(Map<String, dynamic> json) => SkillRequest(
        id: json['id'] as String,
        skillId: json['skill_id'] as String,
        skillTitle: json['skill_title'] as String?,
        requesterId: json['requester_id'] as String,
        requesterName: json['requester_name'] as String?,
        requesterAvatar: json['requester_avatar'] as String?,
        skillOwnerId: json['skill_owner_id'] as String,
        status: RequestStatus.values.asNameMap()[json['status']] ??
            RequestStatus.pending,
        message: json['message'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

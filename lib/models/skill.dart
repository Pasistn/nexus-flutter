class Skill {
  final String id;
  final String userId;
  final String? userName;
  final String? avatarUrl;
  final String skillTitle;
  final String description;
  final double lat;
  final double lng;
  final String? status;
  final DateTime? createdAt;
  final List<String> tags;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;

  const Skill({
    required this.id,
    required this.userId,
    this.userName,
    this.avatarUrl,
    required this.skillTitle,
    required this.description,
    required this.lat,
    required this.lng,
    this.status,
    this.createdAt,
    this.tags = const [],
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    final catJson = json['categories'] as Map<String, dynamic>?;
    return Skill(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      userName: json['user_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      skillTitle: json['skill_title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      tags: json['tags'] is List
          ? (json['tags'] as List<dynamic>).cast<String>()
          : [],
      categoryId: json['category_id'] as String?,
      categoryName: catJson?['name'] as String?,
      categoryIcon: catJson?['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'skill_title': skillTitle,
        'description': description,
        'lat': lat,
        'lng': lng,
        'status': status ?? 'active',
        'tags': tags,
        'category_id': categoryId,
        'points_per_hour': 0,
      };
}

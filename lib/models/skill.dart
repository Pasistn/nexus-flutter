enum SkillType { offering, searching }

class Skill {
  const Skill({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.type = SkillType.offering,
    this.userName,
    this.avatarUrl,
    this.createdAt,
    this.tags = const [],
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
  });

  final String id;
  final String userId;
  final String? userName;
  final String? avatarUrl;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final SkillType type;
  final DateTime? createdAt;
  final List<String> tags;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;

  bool get isSearch => type == SkillType.searching;
  bool get hasOwner => userId.isNotEmpty;

  factory Skill.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    return Skill(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      title: json['skill_title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      type: SkillType.values.asNameMap()[json['skill_type']] ??
          SkillType.offering,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      categoryId: json['category_id'] as String?,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'skill_title': title,
        'description': description,
        'lat': lat,
        'lng': lng,
        'tags': tags,
        'category_id': categoryId,
        'skill_type': type.name,
      };
}

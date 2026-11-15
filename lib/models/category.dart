class SkillCategory {
  const SkillCategory({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;

  factory SkillCategory.fromJson(Map<String, dynamic> json) => SkillCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
      );
}

class Profile {
  final String id;
  final String? userName;
  final String? bio;
  final String? avatarUrl;
  final String? homeAddress;
  final double? homeLat;
  final double? homeLng;

  const Profile({
    required this.id,
    this.userName,
    this.bio,
    this.avatarUrl,
    this.homeAddress,
    this.homeLat,
    this.homeLng,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        userName: json['user_name'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        homeAddress: json['home_address'] as String?,
        homeLat: (json['home_lat'] as num?)?.toDouble(),
        homeLng: (json['home_lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_name': userName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'home_address': homeAddress,
        'home_lat': homeLat,
        'home_lng': homeLng,
      };

  Profile copyWith({
    String? userName,
    String? bio,
    String? avatarUrl,
    String? homeAddress,
    double? homeLat,
    double? homeLng,
  }) =>
      Profile(
        id: id,
        userName: userName ?? this.userName,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        homeAddress: homeAddress ?? this.homeAddress,
        homeLat: homeLat ?? this.homeLat,
        homeLng: homeLng ?? this.homeLng,
      );
}

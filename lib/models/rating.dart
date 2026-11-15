class Rating {
  const Rating({
    required this.id,
    required this.raterId,
    required this.ratedUserId,
    required this.stars,
    this.raterName,
    this.skillId,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String raterId;
  final String? raterName;
  final String ratedUserId;
  final String? skillId;
  final int stars;
  final String? comment;
  final DateTime? createdAt;

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id'] as String,
        raterId: json['rater_id'] as String,
        raterName: json['rater_name'] as String?,
        ratedUserId: json['rated_user_id'] as String,
        skillId: json['skill_id'] as String?,
        stars: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class RatingSummary {
  const RatingSummary({required this.average, required this.reviews});

  static const empty = RatingSummary(average: 0, reviews: []);

  factory RatingSummary.of(List<Rating> reviews) {
    if (reviews.isEmpty) return empty;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.stars);
    return RatingSummary(average: total / reviews.length, reviews: reviews);
  }

  final double average;
  final List<Rating> reviews;

  int get count => reviews.length;
}

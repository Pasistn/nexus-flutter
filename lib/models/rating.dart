class Rating {
  final String id;
  final String raterId;
  final String? raterName;
  final String ratedUserId;
  final String? skillId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  const Rating({
    required this.id,
    required this.raterId,
    this.raterName,
    required this.ratedUserId,
    this.skillId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id'] as String,
        raterId: json['rater_id'] as String,
        raterName: json['rater_name'] as String?,
        ratedUserId: json['rated_user_id'] as String,
        skillId: json['skill_id'] as String?,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class RatingSummary {
  final double avg;
  final int count;
  final List<Rating> reviews;

  const RatingSummary({
    required this.avg,
    required this.count,
    required this.reviews,
  });
}

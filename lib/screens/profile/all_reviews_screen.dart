import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rating.dart';
import '../../providers/ratings_provider.dart';
import '../../widgets/star_rating_bar.dart';

class AllReviewsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AllReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  int? _filterStars; // null = alle

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<RatingsProvider>().getSummary(widget.userId);
    final allReviews = summary?.reviews ?? [];

    final filtered = _filterStars == null
        ? allReviews
        : allReviews.where((r) => r.rating == _filterStars).toList();

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Text('Bewertungen – ${widget.userName}'),
      ),
      body: Column(
        children: [
          // Zusammenfassung + Filter
          Container(
            color: kBgCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null && summary.count > 0) ...[
                  Row(
                    children: [
                      Text(
                        summary.avg.toStringAsFixed(1),
                        style: const TextStyle(
                            color: kNeonOrange,
                            fontSize: 36,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRatingBar(
                              rating: summary.avg,
                              count: summary.count,
                              size: 18,
                              showCount: false),
                          const SizedBox(height: 4),
                          Text('${summary.count} Bewertungen',
                              style: const TextStyle(
                                  color: kTextSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Sternfilter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'Alle'),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) {
                        final stars = 5 - i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _filterChip(stars, '$stars ★'),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded,
                            color: kTextMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _filterStars == null
                              ? 'Noch keine Bewertungen'
                              : 'Keine $_filterStars-Sterne-Bewertungen',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildReviewTile(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int? stars, String label) {
    final active = _filterStars == stars;
    return GestureDetector(
      onTap: () => setState(() => _filterStars = stars),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kNeonOrange : kBgCardElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? kNeonOrange : kBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : kTextSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTile(Rating review) {
    final raterName = review.raterName ?? 'Anonym';
    final createdAt = review.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: kBgCardElevated,
                child: Text(
                  raterName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: kNeonOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(raterName,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                        style:
                            const TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < review.rating ? kNeonOrange : kTextMuted,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/rating.dart';
import '../../providers/ratings_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/review_card.dart';
import '../../widgets/segmented_choice.dart';
import '../../widgets/star_rating.dart';

class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<RatingsProvider>().summaryFor(widget.userId);
    final reviews = [
      for (final r in summary?.reviews ?? const <Rating>[])
        if (_stars == null || r.stars == _stars) r,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName.isEmpty ? 'Bewertungen' : 'Bewertungen · ${widget.userName}',
        ),
      ),
      body: Column(
        children: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null && summary.count > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          summary.average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StarRow(value: summary.average, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              '${summary.count} Bewertungen',
                              style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PillChip(
                        label: 'Alle',
                        selected: _stars == null,
                        onTap: () => setState(() => _stars = null),
                      ),
                      for (var s = 5; s >= 1; s--)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: PillChip(
                            label: '$s ★',
                            selected: _stars == s,
                            onTap: () => setState(() => _stars = s),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reviews.isEmpty
                ? EmptyState(
                    icon: Icons.star_outline_rounded,
                    title: _stars == null
                        ? 'Noch keine Bewertungen'
                        : 'Keine $_stars-Sterne-Bewertungen',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

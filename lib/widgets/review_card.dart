import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/date_format.dart';
import '../models/rating.dart';
import 'star_rating.dart';
import 'user_avatar.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.compact = false});

  final Rating review;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = review.raterName ?? 'Anonym';
    final comment = review.comment;
    final date = review.createdAt;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: name, radius: compact ? 14 : 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (date != null)
                      Text(
                        formatDate(date),
                        style: const TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              StarRow(value: review.stars.toDouble(), size: compact ? 14 : 16),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

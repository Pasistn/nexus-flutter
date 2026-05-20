import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/skill.dart';
import '../providers/ratings_provider.dart';
import 'star_rating_bar.dart';

class SkillCardWidget extends StatefulWidget {
  final Skill skill;

  const SkillCardWidget({super.key, required this.skill});

  @override
  State<SkillCardWidget> createState() => _SkillCardWidgetState();
}

class _SkillCardWidgetState extends State<SkillCardWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.skill.userId.isNotEmpty) {
        context.read<RatingsProvider>().loadForUser(widget.skill.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = context
        .watch<RatingsProvider>()
        .getSummary(widget.skill.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              _buildAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.skill.skillTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(widget.skill.userName ?? '',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    if (summary != null)
                      StarRatingBar(
                        rating: summary.avg,
                        count: summary.count,
                        size: 13,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.skill.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 13, height: 1.4)),
          if (widget.skill.categoryName != null) ...[
            const SizedBox(height: 10),
            _buildCategoryBadge(widget.skill.categoryName!, widget.skill.categoryIcon),
          ],
          if (widget.skill.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.skill.tags.take(4).map(_buildTag).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: kBgCardElevated,
      backgroundImage: widget.skill.avatarUrl != null
          ? CachedNetworkImageProvider(widget.skill.avatarUrl!)
          : null,
      child: widget.skill.avatarUrl == null
          ? Text(
              widget.skill.userName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(
                  color: kNeonOrange, fontWeight: FontWeight.w700))
          : null,
    );
  }

  Widget _buildCategoryBadge(String name, String? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: kNeonOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: kNeonOrange.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
          ],
          Text(name,
              style: const TextStyle(
                  color: kNeonOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kBgCardElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorderColor),
      ),
      child: Text(tag,
          style: const TextStyle(color: kTextMuted, fontSize: 11)),
    );
  }
}

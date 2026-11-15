import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/skill.dart';
import '../providers/ratings_provider.dart';
import 'skill_type_style.dart';
import 'star_rating.dart';
import 'user_avatar.dart';

class SkillCard extends StatefulWidget {
  const SkillCard({super.key, required this.skill, this.footer});

  final Skill skill;
  final Widget? footer;

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> {
  @override
  void initState() {
    super.initState();
    context.read<RatingsProvider>().ensureLoaded(widget.skill.userId);
  }

  @override
  void didUpdateWidget(SkillCard old) {
    super.didUpdateWidget(old);
    if (old.skill.userId != widget.skill.userId) {
      context.read<RatingsProvider>().ensureLoaded(widget.skill.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final accent = skill.type.color;
    final summary = context.select<RatingsProvider, ({double avg, int n})?>(
      (p) {
        final s = p.summaryFor(skill.userId);
        return s == null ? null : (avg: s.average, n: s.count);
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skill.isSearch ? kError.withValues(alpha: 0.45) : kBorder,
          width: skill.isSearch ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(url: skill.avatarUrl, name: skill.userName, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      skill.userName ?? 'Unbekannt',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    if (summary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: RatingSummaryLine(
                          average: summary.avg,
                          count: summary.n,
                        ),
                      ),
                  ],
                ),
              ),
              _Tag(label: skill.type.badge, color: accent, filled: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            skill.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (skill.categoryName != null || skill.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (skill.categoryName != null)
                  _Tag(
                    label: [skill.categoryIcon, skill.categoryName]
                        .whereType<String>()
                        .join(' '),
                    color: accent,
                  ),
                for (final tag in skill.tags.take(4))
                  _Tag(label: tag, color: kTextMuted),
              ],
            ),
          ],
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final neutral = color == kTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: neutral ? kSurfaceAlt : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: neutral ? kBorder : color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: filled ? 10 : 11,
          fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

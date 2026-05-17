import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StarRatingBar extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const StarRatingBar({
    super.key,
    required this.rating,
    required this.count,
    this.size = 14,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'Noch keine Bewertungen',
        style: TextStyle(color: kTextMuted, fontSize: size - 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return Icon(Icons.star_rounded, color: kNeonOrange, size: size);
          } else if (i < rating && rating % 1 >= 0.4) {
            return Icon(Icons.star_half_rounded, color: kNeonOrange, size: size);
          } else {
            return Icon(Icons.star_outline_rounded, color: kTextMuted, size: size);
          }
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: TextStyle(color: kTextSecondary, fontSize: size - 2),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onChanged,
    this.size = 36,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = star);
            widget.onChanged(star);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              star <= _selected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: star <= _selected ? kNeonOrange : kTextMuted,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, this.size = 14});

  final double value;
  final double size;

  IconData _iconFor(int i) {
    if (i < value.floor()) return Icons.star_rounded;
    if (i < value && value - value.floor() >= 0.4) {
      return Icons.star_half_rounded;
    }
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            _iconFor(i),
            size: size,
            color: i < value ? kPrimary : kTextMuted,
          ),
      ],
    );
  }
}

class RatingSummaryLine extends StatelessWidget {
  const RatingSummaryLine({
    super.key,
    required this.average,
    required this.count,
    this.size = 13,
  });

  final double average;
  final int count;
  final double size;

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
        StarRow(value: average, size: size),
        const SizedBox(width: 4),
        Text(
          '${average.toStringAsFixed(1)} ($count)',
          style: TextStyle(color: kTextSecondary, fontSize: size - 2),
        ),
      ],
    );
  }
}

class StarPicker extends StatelessWidget {
  const StarPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: () => onChanged(star),
            iconSize: size,
            tooltip: '$star Sterne',
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: star <= value ? kPrimary : kTextMuted,
            ),
          ),
      ],
    );
  }
}

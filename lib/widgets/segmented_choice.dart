import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.label,
    required this.icon,
    this.color = kPrimary,
  });

  final T value;
  final String label;
  final IconData icon;
  final Color color;
}

class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          for (final o in options) Expanded(child: _segment(o)),
        ],
      ),
    );
  }

  Widget _segment(ChoiceOption<T> option) {
    final active = option.value == selected;
    final color = active ? option.color : kTextMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? option.color.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? option.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(option.icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.color = kPrimary,
  });

  final String label;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? color : kTextSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

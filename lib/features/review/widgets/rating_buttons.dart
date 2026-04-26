import 'package:flutter/material.dart';
import '../../../core/services/sm2_service.dart';

class RatingButtons extends StatelessWidget {
  final Map<ReviewRating, int> intervals;
  final void Function(ReviewRating) onRate;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Btn(rating: ReviewRating.again, days: intervals[ReviewRating.again] ?? 1, onTap: onRate),
        const SizedBox(width: 8),
        _Btn(rating: ReviewRating.hard,  days: intervals[ReviewRating.hard]  ?? 1, onTap: onRate),
        const SizedBox(width: 8),
        _Btn(rating: ReviewRating.good,  days: intervals[ReviewRating.good]  ?? 1, onTap: onRate),
        const SizedBox(width: 8),
        _Btn(rating: ReviewRating.easy,  days: intervals[ReviewRating.easy]  ?? 4, onTap: onRate),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final ReviewRating rating;
  final int days;
  final void Function(ReviewRating) onTap;

  const _Btn({required this.rating, required this.days, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rating) {
      ReviewRating.again => ('Again', const Color(0xFFE05252)),
      ReviewRating.hard  => ('Hard',  const Color(0xFFF5A623)),
      ReviewRating.good  => ('Good',  const Color(0xFF3DBA6E)),
      ReviewRating.easy  => ('Easy',  const Color(0xFF7C6FE0)),
    };
    final dayLabel = days == 1 ? '明天' : '$days 天';

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(rating),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: color, fontSize: 13)),
              const SizedBox(height: 2),
              Text(dayLabel,
                  style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }
}

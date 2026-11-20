import 'package:material_ui/material_ui.dart';

import '../models/review_grade.dart';

/// The four self-grading buttons shown after revealing an answer.
/// Colours follow the usual Anki convention: red / orange / green / blue.
class GradeButtons extends StatelessWidget {
  final void Function(ReviewGrade grade) onGrade;
  final Map<ReviewGrade, String>? intervals;

  const GradeButtons({
    super.key,
    required this.onGrade,
    this.intervals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReviewGrade.values.map((grade) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _GradeButton(
              grade: grade,
              interval: intervals?[grade],
              onPressed: () => onGrade(grade),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final ReviewGrade grade;
  final String? interval;
  final VoidCallback onPressed;

  const _GradeButton({
    required this.grade,
    required this.interval,
    required this.onPressed,
  });

  Color _colorFor(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.again:
        return const Color(0xFFD32F2F);
      case ReviewGrade.hard:
        return const Color(0xFFEF6C00);
      case ReviewGrade.good:
        return const Color(0xFF2E7D32);
      case ReviewGrade.easy:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFor(grade);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            grade.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (interval != null) ...[
            const SizedBox(height: 2),
            Text(
              interval!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

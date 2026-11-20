import '../models/review_grade.dart';

/// The outcome of applying SM-2 to one review: the card's new
/// scheduling state, computed purely from the previous state.
class ReviewResult {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;

  const ReviewResult({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
  });

  /// True when the review counted as a pass (quality >= 3).
  bool get passed => repetitions > 0;
}

/// Convenience holder pairing a grade with the result it produced.
class GradedReview {
  final ReviewGrade grade;
  final ReviewResult result;

  const GradedReview({required this.grade, required this.result});
}

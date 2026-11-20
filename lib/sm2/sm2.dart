import '../models/flashcard.dart';
import '../models/review_grade.dart';
import '../utils/dates.dart';
import 'review_result.dart';

/// SuperMemo SM-2 scheduling, as published by Piotr Wozniak.
///
/// Rules:
/// - Quality 0-2 (fail): repetitions reset to 0, interval becomes 1 day.
/// - Quality >= 3 (pass): repetitions + 1; interval is 1 day on the first
///   pass, 6 days on the second, then previous interval x ease factor.
/// - Ease factor: EF' = EF + (0.1 - (5-q) x (0.08 + (5-q) x 0.02)),
///   clamped to a minimum of 1.3.
/// - Next due date is today + interval, at midnight.
class Sm2 {
  /// Minimum allowed ease factor.
  static const double minEaseFactor = 1.3;

  /// Starting ease factor for brand-new cards.
  static const double initialEaseFactor = 2.5;

  /// Computes the new scheduling state for [card] after a review
  /// graded [grade]. Pure function — no I/O, easy to unit test.
  static ReviewResult schedule(Flashcard card, ReviewGrade grade, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final quality = grade.quality;

    final newEase = _nextEaseFactor(card.easeFactor, quality);

    int newRepetitions;
    int newInterval;
    if (quality < 3) {
      // Failed recall: start the learning steps over.
      newRepetitions = 0;
      newInterval = 1;
    } else {
      newRepetitions = card.repetitions + 1;
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (card.intervalDays * newEase).round();
        if (newInterval < 1) newInterval = 1;
      }
    }

    return ReviewResult(
      easeFactor: newEase,
      intervalDays: newInterval,
      repetitions: newRepetitions,
      dueAt: daysFromNow(newInterval, from: at),
    );
  }

  /// Applies one SM-2 step to [card] and returns the updated card.
  static Flashcard apply(Flashcard card, ReviewGrade grade, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final result = schedule(card, grade, now: at);
    return card.copyWith(
      easeFactor: result.easeFactor,
      intervalDays: result.intervalDays,
      repetitions: result.repetitions,
      dueAt: result.dueAt,
      lastReviewedAt: at,
      reviewCount: card.reviewCount + 1,
      updatedAt: at,
    );
  }

  /// SM-2 ease-factor update, clamped at [minEaseFactor].
  static double _nextEaseFactor(double ease, int quality) {
    final q = quality.toDouble();
    final next = ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    return next < minEaseFactor ? minEaseFactor : next;
  }
}

import '../data/card_repository.dart';
import '../data/review_repository.dart';
import '../models/flashcard.dart';
import '../models/review_grade.dart';
import '../sm2/sm2.dart';

/// Drives one study session: the queue of cards, the current card,
/// grading, and the running totals. UI-agnostic and unit-testable.
///
/// Cards graded "Again" go back into the queue (re-queued at the end)
/// so they get another chance in the same session.
class StudySession {
  final CardRepository _cards;
  final ReviewRepository _reviews;

  final List<Flashcard> _queue;
  final List<Flashcard> _againPile = [];

  int _index = 0;
  bool _revealed = false;

  int reviewedCount = 0;
  int againCount = 0;
  int hardCount = 0;
  int goodCount = 0;
  int easyCount = 0;

  StudySession({
    required List<Flashcard> cards,
    CardRepository? cardRepository,
    ReviewRepository? reviewRepository,
  })  : _queue = List.of(cards),
        _cards = cardRepository ?? CardRepository(),
        _reviews = reviewRepository ?? ReviewRepository();

  /// Cards still to review in this session (including re-queued ones).
  int get remaining => _queue.length - _index + _againPile.length;

  /// The card currently on screen, or null when finished.
  Flashcard? get current => isFinished ? null : _queue[_index];

  /// Whether the answer side is showing.
  bool get revealed => _revealed;

  /// True when every card (including re-queued ones) is graded.
  bool get isFinished => _index >= _queue.length && _againPile.isEmpty;

  /// Progress 0.0-1.0 for the progress bar.
  double get progress {
    final totalCards = _queue.length + _againPile.length + reviewedCount;
    if (totalCards == 0) return 1.0;
    return reviewedCount / totalCards;
  }

  /// Reveal the answer side of the current card.
  void reveal() {
    _revealed = true;
  }

  /// Grade the current card, persist the SM-2 update + review log,
  /// and advance. "Again" cards are re-queued for later in the session.
  Future<void> grade(ReviewGrade grade) async {
    final card = current;
    if (card == null) return;
    final now = DateTime.now();
    final result = Sm2.schedule(card, grade, now: now);
    final updated = Sm2.apply(card, grade, now: now);
    await _cards.update(updated);
    await _reviews.logReview(
      card: card,
      grade: grade,
      result: result,
      at: now,
    );

    reviewedCount += 1;
    switch (grade) {
      case ReviewGrade.again:
        againCount += 1;
        _againPile.add(updated);
      case ReviewGrade.hard:
        hardCount += 1;
      case ReviewGrade.good:
        goodCount += 1;
      case ReviewGrade.easy:
        easyCount += 1;
    }

    _index += 1;
    if (_index >= _queue.length && _againPile.isNotEmpty) {
      _queue.addAll(_againPile);
      _againPile.clear();
    }
    _revealed = false;
  }

  /// Human preview of the interval each grade would give the current
  /// card, e.g. {'again': '1d', 'hard': '1d', 'good': '6d', 'easy': '8d'}.
  Map<ReviewGrade, String> intervalPreview({DateTime? now}) {
    final card = current;
    if (card == null) return const {};
    final at = now ?? DateTime.now();
    final preview = <ReviewGrade, String>{};
    for (final grade in ReviewGrade.values) {
      final result = Sm2.schedule(card, grade, now: at);
      preview[grade] = _intervalLabel(result.intervalDays);
    }
    return preview;
  }

  String _intervalLabel(int days) {
    if (days < 1) return '<1d';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    final months = days ~/ 30;
    if (months < 12) return '${months}mo';
    final years = (months / 12).toStringAsFixed(1);
    return '${years}y';
  }

  /// One-line summary of the session, e.g. "Reviewed 12 · 2 again".
  String get summaryLine {
    final parts = <String>['Reviewed $reviewedCount'];
    if (againCount > 0) parts.add('$againCount again');
    if (hardCount > 0) parts.add('$hardCount hard');
    if (goodCount > 0) parts.add('$goodCount good');
    if (easyCount > 0) parts.add('$easyCount easy');
    return parts.join(' · ');
  }
}

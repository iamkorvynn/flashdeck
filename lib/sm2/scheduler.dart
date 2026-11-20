import '../models/flashcard.dart';
import '../utils/dates.dart';

/// Builds the queue of cards to study and answers "what is due?"
/// questions. Pure logic over already-loaded cards.
class Scheduler {
  /// Cards due for review right now, most overdue first.
  ///
  /// New cards (never reviewed) are always due and come first,
  /// then overdue cards by due date, then cards due today.
  static List<Flashcard> dueQueue(List<Flashcard> cards, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final due = cards.where((c) => !c.dueAt.isAfter(at)).toList();
    due.sort((a, b) {
      // New cards first.
      if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
      final byDue = a.dueAt.compareTo(b.dueAt);
      if (byDue != 0) return byDue;
      return a.createdAt.compareTo(b.createdAt);
    });
    return due;
  }

  /// Cards whose due date falls on [day] (used for the forecast strip).
  static List<Flashcard> dueOn(List<Flashcard> cards, DateTime day) {
    final start = startOfDay(day);
    final end = start.add(const Duration(days: 1));
    return cards
        .where((c) => !c.dueAt.isBefore(start) && c.dueAt.isBefore(end))
        .toList();
  }

  /// Counts of cards due on each of the next [days] days, starting today.
  /// Index 0 is today.
  static List<int> forecast(List<Flashcard> cards, int days, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final counts = List<int>.filled(days, 0);
    for (final card in cards) {
      final diff = startOfDay(card.dueAt).difference(startOfDay(at)).inDays;
      if (diff >= 0 && diff < days) counts[diff] += 1;
    }
    return counts;
  }

  /// Total cards that are overdue (due before today).
  static int overdueCount(List<Flashcard> cards, {DateTime? now}) {
    final today = startOfDay(now ?? DateTime.now());
    return cards.where((c) => c.dueAt.isBefore(today)).length;
  }

  /// Total cards that are new (never reviewed).
  static int newCount(List<Flashcard> cards) =>
      cards.where((c) => c.isNew).length;

  /// Total cards that have been learned at least once (repetitions > 0).
  static int learnedCount(List<Flashcard> cards) =>
      cards.where((c) => c.isLearned).length;
}

import 'package:flashdeck/models/flashcard.dart';
import 'package:flashdeck/sm2/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

Flashcard card({
  required String id,
  DateTime? dueAt,
  int reviewCount = 0,
  int repetitions = 0,
  DateTime? createdAt,
}) {
  final now = DateTime(2026, 11, 20, 9, 0);
  return Flashcard(
    id: id,
    deckId: 'deck-1',
    front: 'Q $id',
    back: 'A $id',
    createdAt: createdAt ?? now,
    updatedAt: now,
    easeFactor: 2.5,
    intervalDays: 1,
    repetitions: repetitions,
    dueAt: dueAt ?? now,
    lastReviewedAt: reviewCount == 0 ? null : now,
    reviewCount: reviewCount,
  );
}

void main() {
  final now = DateTime(2026, 11, 20, 9, 0);

  group('Scheduler.dueQueue', () {
    test('returns only cards due now or earlier', () {
      final cards = [
        card(id: 'due', dueAt: DateTime(2026, 11, 19)),
        card(id: 'future', dueAt: DateTime(2026, 11, 25)),
        card(id: 'today', dueAt: DateTime(2026, 11, 20, 8, 0)),
      ];
      final due = Scheduler.dueQueue(cards, now: now);
      expect(due.map((c) => c.id), containsAll(['due', 'today']));
      expect(due.map((c) => c.id), isNot(contains('future')));
    });

    test('new cards come before reviewed overdue cards', () {
      final cards = [
        card(
          id: 'old-overdue',
          dueAt: DateTime(2026, 11, 10),
          reviewCount: 3,
          repetitions: 2,
        ),
        card(id: 'brand-new', dueAt: DateTime(2026, 11, 20)),
      ];
      final due = Scheduler.dueQueue(cards, now: now);
      expect(due.first.id, 'brand-new');
    });

    test('overdue cards ordered most-overdue first', () {
      final cards = [
        card(id: 'a', dueAt: DateTime(2026, 11, 19), reviewCount: 1),
        card(id: 'b', dueAt: DateTime(2026, 11, 15), reviewCount: 1),
      ];
      final due = Scheduler.dueQueue(cards, now: now);
      expect(due.map((c) => c.id).toList(), ['b', 'a']);
    });
  });

  group('Scheduler counts and forecast', () {
    test('forecast counts cards due each of the next 7 days', () {
      final cards = [
        card(id: 't1', dueAt: DateTime(2026, 11, 20), reviewCount: 1),
        card(id: 't2', dueAt: DateTime(2026, 11, 20), reviewCount: 1),
        card(id: 'tom', dueAt: DateTime(2026, 11, 21), reviewCount: 1),
        card(id: 'far', dueAt: DateTime(2026, 11, 30), reviewCount: 1),
      ];
      final forecast = Scheduler.forecast(cards, 7, now: now);
      expect(forecast, [2, 1, 0, 0, 0, 0, 0]);
    });

    test('overdueCount counts only cards due before today', () {
      final cards = [
        card(id: 'a', dueAt: DateTime(2026, 11, 19), reviewCount: 1),
        card(id: 'b', dueAt: DateTime(2026, 11, 20), reviewCount: 1),
        card(id: 'c', dueAt: DateTime(2026, 11, 21), reviewCount: 1),
      ];
      expect(Scheduler.overdueCount(cards, now: now), 1);
    });

    test('newCount and learnedCount split cards correctly', () {
      final cards = [
        card(id: 'n1'),
        card(id: 'n2'),
        card(id: 'l1', reviewCount: 2, repetitions: 1),
      ];
      expect(Scheduler.newCount(cards), 2);
      expect(Scheduler.learnedCount(cards), 1);
    });
  });
}

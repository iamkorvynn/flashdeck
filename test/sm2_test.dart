import 'package:flashdeck/models/flashcard.dart';
import 'package:flashdeck/models/review_grade.dart';
import 'package:flashdeck/sm2/sm2.dart';
import 'package:flutter_test/flutter_test.dart';

Flashcard newCard() => Flashcard.create(
      deckId: 'deck-1',
      front: 'What is 2 + 2?',
      back: '4',
    );

void main() {
  group('Sm2.schedule', () {
    test('first Good pass: 1 day interval, 1 repetition, ease unchanged', () {
      final card = newCard();
      final result = Sm2.schedule(card, ReviewGrade.good);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, closeTo(2.5, 0.001));
    });

    test('first Easy pass: ease rises by 0.1', () {
      final card = newCard();
      final result = Sm2.schedule(card, ReviewGrade.easy);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, closeTo(2.6, 0.001));
    });

    test('first Hard pass: ease drops to 2.36', () {
      final card = newCard();
      final result = Sm2.schedule(card, ReviewGrade.hard);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, closeTo(2.36, 0.001));
    });

    test('second Good pass: 6 day interval', () {
      final once = Sm2.apply(newCard(), ReviewGrade.good);
      final result = Sm2.schedule(once, ReviewGrade.good);
      expect(result.repetitions, 2);
      expect(result.intervalDays, 6);
    });

    test('third Good pass: interval grows by ease factor (6 x 2.5 = 15)', () {
      var card = newCard();
      card = Sm2.apply(card, ReviewGrade.good);
      card = Sm2.apply(card, ReviewGrade.good);
      final result = Sm2.schedule(card, ReviewGrade.good);
      expect(result.repetitions, 3);
      expect(result.intervalDays, 15);
    });

    test('Again resets repetitions and interval to 1 day', () {
      var card = newCard();
      card = Sm2.apply(card, ReviewGrade.good);
      card = Sm2.apply(card, ReviewGrade.good);
      expect(card.repetitions, 2);
      final result = Sm2.schedule(card, ReviewGrade.again);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
    });

    test('Again drops ease: 2.5 -> 1.7', () {
      final card = newCard();
      final result = Sm2.schedule(card, ReviewGrade.again);
      expect(result.easeFactor, closeTo(1.7, 0.001));
    });

    test('ease factor never drops below 1.3', () {
      var card = newCard();
      for (var i = 0; i < 10; i++) {
        card = Sm2.apply(card, ReviewGrade.again);
      }
      expect(card.easeFactor, closeTo(1.3, 0.001));
      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('due date is today + interval at midnight', () {
      final card = newCard();
      final now = DateTime(2026, 11, 20, 9, 30);
      final result = Sm2.schedule(card, ReviewGrade.good, now: now);
      expect(result.dueAt, DateTime(2026, 11, 21));
    });

    test('apply() bumps review count and last reviewed', () {
      final card = newCard();
      final now = DateTime(2026, 11, 20, 9, 30);
      final updated = Sm2.apply(card, ReviewGrade.good, now: now);
      expect(updated.reviewCount, 1);
      expect(updated.lastReviewedAt, now);
      expect(updated.isDue, isFalse);
    });
  });
}

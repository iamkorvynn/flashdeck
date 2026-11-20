import 'package:flashdeck/data/card_repository.dart';
import 'package:flashdeck/data/deck_repository.dart';
import 'package:flashdeck/data/review_repository.dart';
import 'package:flashdeck/models/deck.dart';
import 'package:flashdeck/models/flashcard.dart';
import 'package:flashdeck/models/review_grade.dart';
import 'package:flashdeck/sm2/sm2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  late DeckRepository decks;
  late CardRepository cards;
  late ReviewRepository reviews;
  late Deck deck;
  late Flashcard card;

  setUpAll(initTestDb);

  setUp(() async {
    await resetTestDb();
    decks = DeckRepository();
    cards = CardRepository();
    reviews = ReviewRepository();
    deck = Deck.create(name: 'D');
    await decks.insert(deck);
    card = Flashcard.create(deckId: deck.id, front: 'Q', back: 'A');
    await cards.insert(card);
  });

  tearDown(resetTestDb);

  Future<void> logGrade(ReviewGrade grade, DateTime at) async {
    final result = Sm2.schedule(card, grade, now: at);
    await reviews.logReview(card: card, grade: grade, result: result, at: at);
  }

  test('retention is null with no reviews', () async {
    expect(await reviews.retention(), isNull);
  });

  test('retention counts passes over total reviews', () async {
    final now = DateTime.now();
    await logGrade(ReviewGrade.good, now);
    await logGrade(ReviewGrade.again, now);
    await logGrade(ReviewGrade.easy, now);
    await logGrade(ReviewGrade.hard, now);
    expect(await reviews.retention(), closeTo(0.75, 0.001));
  });

  test('gradeCounts splits by grade', () async {
    final now = DateTime.now();
    await logGrade(ReviewGrade.good, now);
    await logGrade(ReviewGrade.good, now);
    await logGrade(ReviewGrade.again, now);
    final counts = await reviews.gradeCounts();
    expect(counts['good'], 2);
    expect(counts['again'], 1);
    expect(counts['hard'], 0);
    expect(counts['easy'], 0);
  });

  test('currentStreak counts consecutive review days', () async {
    final today = DateTime.now();
    await logGrade(ReviewGrade.good, today);
    await logGrade(
      ReviewGrade.good,
      today.subtract(const Duration(days: 1)),
    );
    await logGrade(
      ReviewGrade.good,
      today.subtract(const Duration(days: 2)),
    );
    expect(await reviews.currentStreak(), 3);
  });

  test('streak breaks on a missed day', () async {
    final today = DateTime.now();
    await logGrade(ReviewGrade.good, today);
    await logGrade(
      ReviewGrade.good,
      today.subtract(const Duration(days: 2)),
    );
    expect(await reviews.currentStreak(), 1);
  });

  test('streak is 0 with no reviews', () async {
    expect(await reviews.currentStreak(), 0);
  });

  test('totalReviews scopes to a deck', () async {
    final other = Deck.create(name: 'Other');
    await decks.insert(other);
    final otherCard =
        Flashcard.create(deckId: other.id, front: 'Q2', back: 'A2');
    await cards.insert(otherCard);
    final now = DateTime.now();
    await logGrade(ReviewGrade.good, now);
    final result = Sm2.schedule(otherCard, ReviewGrade.good, now: now);
    await reviews.logReview(
      card: otherCard,
      grade: ReviewGrade.good,
      result: result,
      at: now,
    );
    expect(await reviews.totalReviews(), 2);
    expect(await reviews.totalReviews(deckId: deck.id), 1);
    expect(await reviews.totalReviews(deckId: other.id), 1);
  });
}

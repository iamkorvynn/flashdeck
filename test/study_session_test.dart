import 'package:flashdeck/data/card_repository.dart';
import 'package:flashdeck/data/deck_repository.dart';
import 'package:flashdeck/data/review_repository.dart';
import 'package:flashdeck/models/deck.dart';
import 'package:flashdeck/models/flashcard.dart';
import 'package:flashdeck/models/review_grade.dart';
import 'package:flashdeck/study/study_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  late DeckRepository decks;
  late CardRepository cards;
  late ReviewRepository reviews;
  late Deck deck;

  setUpAll(initTestDb);

  setUp(() async {
    await resetTestDb();
    decks = DeckRepository();
    cards = CardRepository();
    reviews = ReviewRepository();
    deck = Deck.create(name: 'D');
    await decks.insert(deck);
  });

  tearDown(resetTestDb);

  Future<Flashcard> addCard(String front) async {
    final card = Flashcard.create(deckId: deck.id, front: front, back: 'A');
    await cards.insert(card);
    return card;
  }

  test('session walks the queue and finishes', () async {
    final a = await addCard('Q1');
    final b = await addCard('Q2');
    final session = StudySession(
      cards: [a, b],
      cardRepository: cards,
      reviewRepository: reviews,
    );
    expect(session.current?.id, a.id);
    expect(session.isFinished, isFalse);

    await session.grade(ReviewGrade.good);
    expect(session.reviewedCount, 1);
    expect(session.current?.id, b.id);

    await session.grade(ReviewGrade.easy);
    expect(session.isFinished, isTrue);
    expect(session.reviewedCount, 2);
    expect(session.current, isNull);
  });

  test('Again re-queues the card for later in the session', () async {
    final a = await addCard('Q1');
    final b = await addCard('Q2');
    final session = StudySession(
      cards: [a, b],
      cardRepository: cards,
      reviewRepository: reviews,
    );
    await session.grade(ReviewGrade.again);
    expect(session.againCount, 1);
    expect(session.isFinished, isFalse);
    expect(session.current?.id, b.id);

    await session.grade(ReviewGrade.good);
    // The failed card comes back now.
    expect(session.isFinished, isFalse);
    expect(session.current?.id, a.id);

    await session.grade(ReviewGrade.good);
    expect(session.isFinished, isTrue);
    expect(session.reviewedCount, 3);
  });

  test('grading persists SM-2 state and the review log', () async {
    final a = await addCard('Q1');
    final session = StudySession(
      cards: [a],
      cardRepository: cards,
      reviewRepository: reviews,
    );
    await session.grade(ReviewGrade.good);
    final updated = await cards.getById(a.id);
    expect(updated?.repetitions, 1);
    expect(updated?.intervalDays, 1);
    expect(updated?.reviewCount, 1);
    expect(await reviews.totalReviews(), 1);
  });

  test('intervalPreview gives a label per grade', () async {
    final a = await addCard('Q1');
    final session = StudySession(
      cards: [a],
      cardRepository: cards,
      reviewRepository: reviews,
    );
    final preview = session.intervalPreview();
    expect(preview[ReviewGrade.again], '1d');
    expect(preview[ReviewGrade.good], '1d');
    expect(preview[ReviewGrade.easy], '1d');
  });

  test('empty session is finished immediately', () async {
    final session = StudySession(
      cards: [],
      cardRepository: cards,
      reviewRepository: reviews,
    );
    expect(session.isFinished, isTrue);
    expect(session.progress, 1.0);
  });
}

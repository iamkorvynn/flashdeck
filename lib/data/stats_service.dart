import '../models/flashcard.dart';
import '../sm2/scheduler.dart';
import 'card_repository.dart';
import 'review_repository.dart';

/// Aggregated numbers shown on the home screen and the stats screen.
class DeckStats {
  final String deckId;
  final int totalCards;
  final int dueCards;
  final int newCards;
  final int learnedCards;
  final double? retention;
  final int streak;
  final int totalReviews;
  final List<int> forecast7;

  const DeckStats({
    required this.deckId,
    required this.totalCards,
    required this.dueCards,
    required this.newCards,
    required this.learnedCards,
    required this.retention,
    required this.streak,
    required this.totalReviews,
    required this.forecast7,
  });
}

/// Library-wide totals for the home header.
class LibraryStats {
  final int totalDecks;
  final int totalCards;
  final int dueCards;
  final int newCards;
  final int learnedCards;
  final double? retention;
  final int streak;
  final int totalReviews;
  final int reviewsToday;

  const LibraryStats({
    required this.totalDecks,
    required this.totalCards,
    required this.dueCards,
    required this.newCards,
    required this.learnedCards,
    required this.retention,
    required this.streak,
    required this.totalReviews,
    required this.reviewsToday,
  });
}

class StatsService {
  final CardRepository _cards;
  final ReviewRepository _reviews;

  StatsService([CardRepository? cards, ReviewRepository? reviews])
      : _cards = cards ?? CardRepository(),
        _reviews = reviews ?? ReviewRepository();

  Future<DeckStats> deckStats(String deckId) async {
    final cards = await _cards.getByDeck(deckId);
    final due = Scheduler.dueQueue(cards);
    return DeckStats(
      deckId: deckId,
      totalCards: cards.length,
      dueCards: due.length,
      newCards: Scheduler.newCount(cards),
      learnedCards: Scheduler.learnedCount(cards),
      retention: await _reviews.retention(deckId: deckId),
      streak: await _reviews.currentStreak(deckId: deckId),
      totalReviews: await _reviews.totalReviews(deckId: deckId),
      forecast7: Scheduler.forecast(cards, 7),
    );
  }

  Future<LibraryStats> libraryStats(int deckCount) async {
    final cards = await _cards.getAll();
    final due = Scheduler.dueQueue(cards);
    return LibraryStats(
      totalDecks: deckCount,
      totalCards: cards.length,
      dueCards: due.length,
      newCards: Scheduler.newCount(cards),
      learnedCards: Scheduler.learnedCount(cards),
      retention: await _reviews.retention(),
      streak: await _reviews.currentStreak(),
      totalReviews: await _reviews.totalReviews(),
      reviewsToday: await _reviews.reviewsInLastDays(1),
    );
  }

  /// Per-deck card lists for the forecast strip on the stats screen.
  Future<List<Flashcard>> allCards() => _cards.getAll();
}

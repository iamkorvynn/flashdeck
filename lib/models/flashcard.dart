import '../utils/dates.dart';
import '../utils/ids.dart';

/// One flashcard: a front (prompt) and a back (answer), plus its
/// SM-2 scheduling state. A brand-new card has [repetitions] 0,
/// [intervalDays] 0, ease 2.5 and is due immediately.
class Flashcard {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// SM-2 ease factor. Starts at 2.5, never drops below 1.3.
  final double easeFactor;

  /// Current SM-2 interval in whole days.
  final int intervalDays;

  /// Consecutive successful reviews (resets to 0 on a fail).
  final int repetitions;

  /// When this card is next due for review.
  final DateTime dueAt;

  /// When this card was last reviewed, or null if never.
  final DateTime? lastReviewedAt;

  /// Total number of reviews ever recorded for this card.
  final int reviewCount;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.updatedAt,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    required this.lastReviewedAt,
    required this.reviewCount,
  });

  /// Creates a brand-new card that is due right away.
  factory Flashcard.create({
    required String deckId,
    required String front,
    required String back,
  }) {
    final now = DateTime.now();
    return Flashcard(
      id: newId(),
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      createdAt: now,
      updatedAt: now,
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
      dueAt: now,
      lastReviewedAt: null,
      reviewCount: 0,
    );
  }

  /// True when the card has never been reviewed.
  bool get isNew => reviewCount == 0;

  /// True when the card is due for review right now.
  bool get isDue => !dueAt.isAfter(DateTime.now());

  /// True when the card has been reviewed and passed at least once.
  bool get isLearned => repetitions > 0;

  /// Whole days until this card is due (negative when overdue).
  int get daysUntilDue => daysUntil(dueAt);

  factory Flashcard.fromMap(Map<String, Object?> map) {
    final lastReviewed = map['last_reviewed_at'] as int?;
    return Flashcard(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      front: map['front'] as String,
      back: map['back'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      easeFactor: (map['ease_factor'] as num).toDouble(),
      intervalDays: map['interval_days'] as int,
      repetitions: map['repetitions'] as int,
      dueAt: DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
      lastReviewedAt: lastReviewed == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastReviewed),
      reviewCount: map['review_count'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'due_at': dueAt.millisecondsSinceEpoch,
      'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
      'review_count': reviewCount,
    };
  }

  Flashcard copyWith({
    String? front,
    String? back,
    DateTime? updatedAt,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    bool clearLastReviewed = false,
    int? reviewCount,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt:
          clearLastReviewed ? null : (lastReviewedAt ?? this.lastReviewedAt),
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

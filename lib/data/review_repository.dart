import '../models/flashcard.dart';
import '../models/review_grade.dart';
import '../sm2/review_result.dart';
import '../utils/dates.dart';
import '../utils/ids.dart';
import 'database_helper.dart';

/// Records graded reviews and derives retention + streak statistics
/// from the review log.
class ReviewRepository {
  final DatabaseHelper _helper;

  ReviewRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  /// Logs one graded review. Call alongside the card update, ideally
  /// in the same transaction from the caller.
  Future<void> logReview({
    required Flashcard card,
    required ReviewGrade grade,
    required ReviewResult result,
    DateTime? at,
  }) async {
    final db = await _helper.database;
    final reviewedAt = at ?? DateTime.now();
    await db.insert('reviews', <String, Object?>{
      'id': newId(),
      'card_id': card.id,
      'deck_id': card.deckId,
      'grade': grade.name,
      'quality': grade.quality,
      'reviewed_at': reviewedAt.millisecondsSinceEpoch,
      'interval_after': result.intervalDays,
      'ease_after': result.easeFactor,
    });
  }

  /// Total reviews ever recorded, optionally scoped to one deck.
  Future<int> totalReviews({String? deckId}) async {
    final db = await _helper.database;
    final where = deckId == null ? null : 'deck_id = ?';
    final args = deckId == null ? null : <Object?>[deckId];
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM reviews${where == null ? '' : ' WHERE $where'}',
      args,
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Reviews in the last [days] days, optionally scoped to one deck.
  Future<int> reviewsInLastDays(int days, {String? deckId}) async {
    final db = await _helper.database;
    final since = startOfDay(DateTime.now())
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final where = deckId == null
        ? 'reviewed_at >= ?'
        : 'deck_id = ? AND reviewed_at >= ?';
    final args = deckId == null
        ? <Object?>[since]
        : <Object?>[deckId, since];
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM reviews WHERE $where',
      args,
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Retention: share of reviews with quality >= 3 (a pass).
  /// Returns null when there are no reviews yet.
  Future<double?> retention({String? deckId}) async {
    final db = await _helper.database;
    final where = deckId == null ? '' : ' WHERE deck_id = ?';
    final args = deckId == null ? null : <Object?>[deckId];
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, '
      'SUM(CASE WHEN quality >= 3 THEN 1 ELSE 0 END) AS passed '
      'FROM reviews$where',
      args,
    );
    final total = (rows.first['total'] as int?) ?? 0;
    if (total == 0) return null;
    final passed = (rows.first['passed'] as int?) ?? 0;
    return passed / total;
  }

  /// Per-grade counts, e.g. {'again': 3, 'hard': 5, 'good': 12, 'easy': 4}.
  Future<Map<String, int>> gradeCounts({String? deckId}) async {
    final db = await _helper.database;
    final where = deckId == null ? '' : ' WHERE deck_id = ?';
    final args = deckId == null ? null : <Object?>[deckId];
    final rows = await db.rawQuery(
      'SELECT grade, COUNT(*) AS n FROM reviews$where GROUP BY grade',
      args,
    );
    final counts = <String, int>{
      'again': 0,
      'hard': 0,
      'good': 0,
      'easy': 0,
    };
    for (final row in rows) {
      counts[row['grade'] as String] = (row['n'] as int?) ?? 0;
    }
    return counts;
  }

  /// Current daily streak: consecutive days (including today when a
  /// review happened today) with at least one review.
  Future<int> currentStreak({String? deckId}) async {
    final db = await _helper.database;
    final where = deckId == null ? '' : ' AND deck_id = ?';
    final args = deckId == null ? null : <Object?>[deckId];
    final rows = await db.rawQuery(
      'SELECT DISTINCT reviewed_at FROM reviews WHERE 1 = 1$where',
      args,
    );
    if (rows.isEmpty) return 0;
    final days = rows
        .map((r) => startOfDay(
              DateTime.fromMillisecondsSinceEpoch(r['reviewed_at'] as int),
            ))
        .toSet();
    var streak = 0;
    var cursor = startOfDay(DateTime.now());
    // If nothing reviewed today, the streak counts up to yesterday.
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

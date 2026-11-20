import '../models/flashcard.dart';
import 'database_helper.dart';

/// CRUD and study queries for flashcards.
class CardRepository {
  final DatabaseHelper _helper;

  CardRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<void> insert(Flashcard card) async {
    final db = await _helper.database;
    await db.insert('cards', card.toMap());
  }

  Future<Flashcard?> getById(String id) async {
    final db = await _helper.database;
    final rows = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Flashcard.fromMap(rows.first);
  }

  /// All cards in a deck, oldest first (creation order).
  Future<List<Flashcard>> getByDeck(String deckId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: <Object?>[deckId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  /// Cards due for review in a deck, most overdue first.
  Future<List<Flashcard>> getDueByDeck(String deckId, {DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final db = await _helper.database;
    final rows = await db.query(
      'cards',
      where: 'deck_id = ? AND due_at <= ?',
      whereArgs: <Object?>[deckId, at],
      orderBy: 'due_at ASC, created_at ASC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  /// Cards due for review across all decks, most overdue first.
  Future<List<Flashcard>> getAllDue({DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final db = await _helper.database;
    final rows = await db.query(
      'cards',
      where: 'due_at <= ?',
      whereArgs: <Object?>[at],
      orderBy: 'due_at ASC, created_at ASC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  /// All cards in the whole library (used for stats + forecast).
  Future<List<Flashcard>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('cards', orderBy: 'created_at ASC');
    return rows.map(Flashcard.fromMap).toList();
  }

  /// Number of cards in a deck.
  Future<int> countByDeck(String deckId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM cards WHERE deck_id = ?',
      <Object?>[deckId],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Number of due cards in a deck.
  Future<int> countDueByDeck(String deckId, {DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM cards WHERE deck_id = ? AND due_at <= ?',
      <Object?>[deckId, at],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// Number of due cards across all decks.
  Future<int> countAllDue({DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM cards WHERE due_at <= ?',
      <Object?>[at],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<void> update(Flashcard card) async {
    final db = await _helper.database;
    await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[card.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('cards', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Deletes every card in a deck (normally handled by CASCADE).
  Future<void> deleteByDeck(String deckId) async {
    final db = await _helper.database;
    await db.delete('cards', where: 'deck_id = ?', whereArgs: <Object?>[deckId]);
  }

  /// Full-text-ish search across front and back, newest first.
  /// Returns cards paired with their deck id for display.
  Future<List<Flashcard>> search(String query) async {
    final db = await _helper.database;
    final rows = await db.query(
      'cards',
      where: 'front LIKE ? OR back LIKE ?',
      whereArgs: <Object?>['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }
}

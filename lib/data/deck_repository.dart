import '../models/deck.dart';
import 'database_helper.dart';

/// CRUD for decks. All reads are ordered newest-first unless stated.
class DeckRepository {
  final DatabaseHelper _helper;

  DeckRepository([DatabaseHelper? helper])
      : _helper = helper ?? DatabaseHelper.instance;

  Future<void> insert(Deck deck) async {
    final db = await _helper.database;
    await db.insert('decks', deck.toMap());
  }

  Future<Deck?> getById(String id) async {
    final db = await _helper.database;
    final rows = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Deck.fromMap(rows.first);
  }

  Future<List<Deck>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('decks', orderBy: 'created_at DESC');
    return rows.map(Deck.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM decks');
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<void> update(Deck deck) async {
    final db = await _helper.database;
    await db.update(
      'decks',
      deck.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[deck.id],
    );
  }

  /// Deletes the deck; its cards and reviews go with it (CASCADE).
  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('decks', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Case-insensitive name search, newest first.
  Future<List<Deck>> search(String query) async {
    final db = await _helper.database;
    final rows = await db.query(
      'decks',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: <Object?>['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return rows.map(Deck.fromMap).toList();
  }
}

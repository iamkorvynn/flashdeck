import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite database file and its schema.
///
/// Tables:
/// - decks: id, name, description, created_at, updated_at
/// - cards: id, deck_id, front, back, SM-2 state, timestamps
/// - reviews: one row per graded review, used for retention + streaks
///
/// The app ships with an EMPTY database: no seed decks or cards.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _fileName = 'flashdeck.db';

  /// Current schema version. Bump when changing onCreate/onUpgrade.
  static const int schemaVersion = 1;

  /// Test-only override for the database path. Tests set this to
  /// [inMemoryDatabasePath] so each test file gets an isolated database
  /// instead of sharing the on-disk file.
  static String? testDatabasePath;

  Database? _db;

  /// Opens (creating if needed) and returns the database.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await openDatabase(
      testDatabasePath ?? p.join(await getDatabasesPath(), _fileName),
      version: schemaVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
    _db = db;
    return db;
  }

  Future<void> _onConfigure(Database db) async {
    // Enforce foreign keys so deleting a deck removes its cards/reviews.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        due_at INTEGER NOT NULL,
        last_reviewed_at INTEGER,
        review_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cards_deck ON cards(deck_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cards_due ON cards(due_at)',
    );
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        grade TEXT NOT NULL,
        quality INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        interval_after INTEGER NOT NULL,
        ease_after REAL NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reviews_date ON reviews(reviewed_at)',
    );
  }

  /// Closes the database. Used by tests; the app keeps it open.
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}

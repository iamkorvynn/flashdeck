import 'dart:convert';

import '../models/deck.dart';
import '../models/flashcard.dart';
import '../utils/ids.dart';
import 'card_repository.dart';
import 'deck_repository.dart';

/// JSON import/export of decks. Format (v1):
/// {
///   "format": "flashdeck",
///   "version": 1,
///   "exported_at": <epoch ms>,
///   "decks": [ { "name": ..., "description": ..., "cards": [ {front, back, ...} ] } ]
/// }
///
/// Export includes SM-2 state so a round-trip preserves scheduling.
/// Import always mints fresh ids so it never collides with existing data.
class ExportService {
  final DeckRepository _decks;
  final CardRepository _cards;

  ExportService([DeckRepository? decks, CardRepository? cards])
      : _decks = decks ?? DeckRepository(),
        _cards = cards ?? CardRepository();

  /// Serialises every deck (with its cards) to a JSON string.
  Future<String> exportAll() async {
    final decks = await _decks.getAll();
    final out = <Map<String, Object?>>[];
    for (final deck in decks) {
      final cards = await _cards.getByDeck(deck.id);
      out.add(_deckToJson(deck, cards));
    }
    return jsonEncode(<String, Object?>{
      'format': 'flashdeck',
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'decks': out,
    });
  }

  /// Serialises a single deck (with its cards) to a JSON string.
  Future<String> exportDeck(String deckId) async {
    final deck = await _decks.getById(deckId);
    if (deck == null) {
      throw StateError('Deck not found: $deckId');
    }
    final cards = await _cards.getByDeck(deckId);
    return jsonEncode(<String, Object?>{
      'format': 'flashdeck',
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'decks': <Map<String, Object?>>[_deckToJson(deck, cards)],
    });
  }

  Map<String, Object?> _deckToJson(Deck deck, List<Flashcard> cards) {
    return <String, Object?>{
      'name': deck.name,
      'description': deck.description,
      'created_at': deck.createdAt.millisecondsSinceEpoch,
      'cards': cards
          .map((c) => <String, Object?>{
                'front': c.front,
                'back': c.back,
                'ease_factor': c.easeFactor,
                'interval_days': c.intervalDays,
                'repetitions': c.repetitions,
                'due_at': c.dueAt.millisecondsSinceEpoch,
                'review_count': c.reviewCount,
              })
          .toList(),
    };
  }
}

/// Result of an import: how many decks and cards were created.
class ImportResult {
  final int decksImported;
  final int cardsImported;

  const ImportResult({required this.decksImported, required this.cardsImported});
}

extension ExportServiceImport on ExportService {
  /// Parses [jsonText] and inserts its decks/cards with fresh ids.
  /// Throws [FormatException] on malformed input.
  Future<ImportResult> importJson(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Import must be a JSON object');
    }
    if (decoded['format'] != 'flashdeck') {
      throw const FormatException('Not a FlashDeck export file');
    }
    final decksRaw = decoded['decks'];
    if (decksRaw is! List) {
      throw const FormatException('Export is missing its decks list');
    }

    var decksImported = 0;
    var cardsImported = 0;
    for (final deckRaw in decksRaw) {
      if (deckRaw is! Map<String, Object?>) continue;
      final name = deckRaw['name'];
      if (name is! String || name.trim().isEmpty) continue;
      final deck = Deck.create(
        name: name,
        description: (deckRaw['description'] as String?) ?? '',
      );
      await _decks.insert(deck);
      decksImported += 1;

      final cardsRaw = deckRaw['cards'];
      if (cardsRaw is! List) continue;
      for (final cardRaw in cardsRaw) {
        if (cardRaw is! Map<String, Object?>) continue;
        final front = cardRaw['front'];
        final back = cardRaw['back'];
        if (front is! String || back is! String) continue;
        if (front.trim().isEmpty || back.trim().isEmpty) continue;
        final now = DateTime.now();
        final dueMillis = cardRaw['due_at'];
        final card = Flashcard(
          id: newId(),
          deckId: deck.id,
          front: front.trim(),
          back: back.trim(),
          createdAt: now,
          updatedAt: now,
          easeFactor: (cardRaw['ease_factor'] as num?)?.toDouble() ?? 2.5,
          intervalDays: (cardRaw['interval_days'] as num?)?.toInt() ?? 0,
          repetitions: (cardRaw['repetitions'] as num?)?.toInt() ?? 0,
          dueAt: dueMillis is int
              ? DateTime.fromMillisecondsSinceEpoch(dueMillis)
              : now,
          lastReviewedAt: null,
          reviewCount: (cardRaw['review_count'] as num?)?.toInt() ?? 0,
        );
        await _cards.insert(card);
        cardsImported += 1;
      }
    }
    return ImportResult(
      decksImported: decksImported,
      cardsImported: cardsImported,
    );
  }
}

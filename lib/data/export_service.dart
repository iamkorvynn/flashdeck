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

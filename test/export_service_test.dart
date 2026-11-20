import 'dart:convert';

import 'package:flashdeck/data/card_repository.dart';
import 'package:flashdeck/data/deck_repository.dart';
import 'package:flashdeck/data/export_service.dart';
import 'package:flashdeck/models/deck.dart';
import 'package:flashdeck/models/flashcard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  late DeckRepository decks;
  late CardRepository cards;
  late ExportService exporter;

  setUpAll(initTestDb);

  setUp(() async {
    await resetTestDb();
    decks = DeckRepository();
    cards = CardRepository();
    exporter = ExportService(decks, cards);
  });

  tearDown(resetTestDb);

  test('export of an empty library is valid JSON with no decks', () async {
    final json = await exporter.exportAll();
    final decoded = jsonDecode(json) as Map<String, Object?>;
    expect(decoded['format'], 'flashdeck');
    expect(decoded['version'], 1);
    expect(decoded['decks'], isEmpty);
  });

  test('export includes deck, cards and SM-2 state', () async {
    final deck = Deck.create(name: 'Bio', description: 'cells');
    await decks.insert(deck);
    await cards.insert(
      Flashcard.create(deckId: deck.id, front: 'Q', back: 'A'),
    );
    final decoded =
        jsonDecode(await exporter.exportAll()) as Map<String, Object?>;
    final deckList = decoded['decks'] as List;
    expect(deckList.length, 1);
    final first = deckList.first as Map<String, Object?>;
    expect(first['name'], 'Bio');
    final cardList = first['cards'] as List;
    expect(cardList.length, 1);
    final cardJson = cardList.first as Map<String, Object?>;
    expect(cardJson['front'], 'Q');
    expect(cardJson['ease_factor'], 2.5);
  });

  test('round-trip: export then import restores decks and cards', () async {
    final deck = Deck.create(name: 'Bio');
    await decks.insert(deck);
    await cards.insert(
      Flashcard.create(deckId: deck.id, front: 'Q1', back: 'A1'),
    );
    await cards.insert(
      Flashcard.create(deckId: deck.id, front: 'Q2', back: 'A2'),
    );
    final json = await exporter.exportAll();

    await resetTestDb();
    decks = DeckRepository();
    cards = CardRepository();
    exporter = ExportService(decks, cards);

    final result = await exporter.importJson(json);
    expect(result.decksImported, 1);
    expect(result.cardsImported, 2);
    final restored = await decks.getAll();
    expect(restored.first.name, 'Bio');
    expect((await cards.getByDeck(restored.first.id)).length, 2);
  });

  test('import rejects malformed JSON', () async {
    await expectLater(
      exporter.importJson('not json at all'),
      throwsFormatException,
    );
  });

  test('import rejects non-FlashDeck JSON', () async {
    await expectLater(
      exporter.importJson('{"format": "other", "decks": []}'),
      throwsFormatException,
    );
  });

  test('import skips decks with blank names', () async {
    final result = await exporter.importJson(
      '{"format": "flashdeck", "version": 1, "decks": '
      '[{"name": "  ", "cards": []}, {"name": "Good", "cards": []}]}',
    );
    expect(result.decksImported, 1);
    expect((await decks.getAll()).first.name, 'Good');
  });
}

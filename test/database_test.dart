import 'package:flashdeck/data/card_repository.dart';
import 'package:flashdeck/data/deck_repository.dart';
import 'package:flashdeck/models/deck.dart';
import 'package:flashdeck/models/flashcard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  late DeckRepository decks;
  late CardRepository cards;

  setUpAll(initTestDb);

  setUp(() async {
    await resetTestDb();
    decks = DeckRepository();
    cards = CardRepository();
  });

  tearDown(resetTestDb);

  group('DeckRepository', () {
    test('insert then getById round-trips', () async {
      final deck = Deck.create(name: 'Biology', description: 'Cells');
      await decks.insert(deck);
      final found = await decks.getById(deck.id);
      expect(found?.name, 'Biology');
      expect(found?.description, 'Cells');
    });

    test('getAll returns newest first', () async {
      final first = Deck.create(name: 'First');
      final second = Deck.create(name: 'Second');
      await decks.insert(first);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await decks.insert(second);
      final all = await decks.getAll();
      expect(all.first.name, 'Second');
      expect(all.length, 2);
    });

    test('update renames a deck', () async {
      final deck = Deck.create(name: 'Old');
      await decks.insert(deck);
      await decks.update(deck.copyWith(name: 'New'));
      expect((await decks.getById(deck.id))?.name, 'New');
    });

    test('search finds by name or description', () async {
      await decks.insert(Deck.create(name: 'Biology', description: 'cells'));
      await decks.insert(Deck.create(name: 'History', description: 'wars'));
      final found = await decks.search('bio');
      expect(found.length, 1);
      expect(found.first.name, 'Biology');
    });

    test('delete removes the deck and cascades to its cards', () async {
      final deck = Deck.create(name: 'Temp');
      await decks.insert(deck);
      await cards.insert(Flashcard.create(deckId: deck.id, front: 'Q', back: 'A'));
      await decks.delete(deck.id);
      expect(await decks.getById(deck.id), isNull);
      expect(await cards.getByDeck(deck.id), isEmpty);
    });
  });

  group('CardRepository', () {
    late Deck deck;

    setUp(() async {
      deck = Deck.create(name: 'D');
      await decks.insert(deck);
    });

    test('insert then getByDeck returns the card', () async {
      final card = Flashcard.create(deckId: deck.id, front: 'Q?', back: 'A!');
      await cards.insert(card);
      final found = await cards.getByDeck(deck.id);
      expect(found.length, 1);
      expect(found.first.front, 'Q?');
      expect(found.first.isNew, isTrue);
      expect(found.first.isDue, isTrue);
    });

    test('getDueByDeck excludes future cards', () async {
      final due = Flashcard.create(deckId: deck.id, front: 'due', back: 'x');
      final future = Flashcard.create(deckId: deck.id, front: 'later', back: 'y')
          .copyWith(dueAt: DateTime.now().add(const Duration(days: 5)));
      await cards.insert(due);
      await cards.insert(future);
      final dueList = await cards.getDueByDeck(deck.id);
      expect(dueList.map((c) => c.front), ['due']);
      expect(await cards.countDueByDeck(deck.id), 1);
    });

    test('update edits front and back', () async {
      final card = Flashcard.create(deckId: deck.id, front: 'old', back: 'old');
      await cards.insert(card);
      await cards.update(card.copyWith(front: 'new', back: 'new'));
      final found = await cards.getById(card.id);
      expect(found?.front, 'new');
      expect(found?.back, 'new');
    });

    test('delete removes one card only', () async {
      final a = Flashcard.create(deckId: deck.id, front: 'a', back: 'a');
      final b = Flashcard.create(deckId: deck.id, front: 'b', back: 'b');
      await cards.insert(a);
      await cards.insert(b);
      await cards.delete(a.id);
      final remaining = await cards.getByDeck(deck.id);
      expect(remaining.map((c) => c.front), ['b']);
    });

    test('search finds cards by front or back text', () async {
      await cards.insert(Flashcard.create(deckId: deck.id, front: 'mitochondria', back: 'powerhouse'));
      await cards.insert(Flashcard.create(deckId: deck.id, front: 'nucleus', back: 'control center'));
      final found = await cards.search('powerhouse');
      expect(found.length, 1);
      expect(found.first.front, 'mitochondria');
    });
  });
}

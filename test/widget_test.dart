import 'package:flashdeck/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_db.dart';

void main() {
  setUpAll(initTestDb);

  setUp(resetTestDb);

  tearDown(resetTestDb);

  testWidgets('home shows empty state when no decks exist',
      (tester) async {
    await tester.pumpWidget(const FlashDeckApp());
    // The home screen loads from the ffi database on a background
    // isolate (real time), so pump until the empty state appears.
    for (var i = 0;
        i < 100 && find.text('No decks yet').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('FlashDeck'), findsOneWidget);
    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create a deck'), findsWidgets);
  });
}

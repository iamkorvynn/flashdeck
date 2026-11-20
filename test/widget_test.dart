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
    // The ffi database open runs on a background isolate in real time,
    // so wait for it outside the fake clock, then pump the result.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('FlashDeck'), findsOneWidget);
    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create a deck'), findsWidgets);
  });
}

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flashdeck/data/database_helper.dart';

/// Initialises the ffi database factory so sqflite works in tests,
/// and points the helper at an in-memory database so test files never
/// share (and lock) the same on-disk file.
void initTestDb() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
}

/// Closes the test database. An in-memory database is destroyed on
/// close, so the next test starts from a clean slate.
Future<void> resetTestDb() async {
  await DatabaseHelper.instance.close();
}

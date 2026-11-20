import 'dart:math';

final Random _random = Random();

/// Generates a short, unique, time-ordered id for decks, cards and reviews.
/// No external dependency; safe to use offline.
String newId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final suffix = _random.nextInt(1 << 32).toRadixString(36);
  return '${now.toRadixString(36)}$suffix';
}

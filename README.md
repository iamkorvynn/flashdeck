# FlashDeck

Flashcards with **SM-2 spaced repetition**. Local-first: everything lives
in an on-device SQLite database. No account, no network, no ads, no demo
data — the app starts empty.

## Features

- **Decks** — create, rename and delete decks.
- **Cards** — add, edit and delete flashcards (front = question, back = answer).
- **Study sessions** — tap to flip, then grade your recall:
  Again / Hard / Good / Easy.
- **SM-2 scheduling** — the classic SuperMemo 2 algorithm: 1 day after the
  first pass, 6 days after the second, then the interval grows by your ease
  factor. Failed cards come back sooner and get re-queued in the same session.
- **Due queue** — new cards first, then most-overdue first; a 7-day forecast
  shows what's coming up.
- **Stats** — per-deck and library-wide: due counts, learned cards, retention
  (share of passing reviews), day streak, grade breakdown, review history.
- **Search** — full-library search across card fronts and backs.
- **Import / export** — decks export to JSON (including SM-2 state) for backup;
  paste a FlashDeck export to import it. Imports always mint fresh ids.

## Tech

- Flutter 3.50, Dart 3.14, Material 3 (light + dark).
- `sqflite` for storage; `sqflite_common_ffi` for tests.
- No network calls, no permissions beyond the defaults.

## Build & test

```sh
export PATH=~/workspace/flutter-sdk/flutter/bin:$PATH
export ANDROID_HOME=~/workspace/android-sdk
export JAVA_HOME=~/workspace/android-sdk/jdk17
export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"
export GRADLE_OPTS="-Djava.net.preferIPv4Stack=true"
export GRADLE_USER_HOME=~/workspace/overnight-8-apps/.gradle-home
export TMPDIR=~/workspace/overnight-5-apps/.tmp
export CI=true

flutter analyze
flutter test
flutter build apk --release
```

## Project layout

- `lib/models/` — Deck, Flashcard, ReviewGrade
- `lib/sm2/` — the SM-2 algorithm (`sm2.dart`), due queue & forecast (`scheduler.dart`)
- `lib/data/` — SQLite helper, repositories, stats, JSON import/export
- `lib/study/` — the study-session controller (queue, grading, re-queue)
- `lib/screens/` — home, deck detail, card editor, study, stats, search, import/export, review history, about
- `lib/widgets/` — flip card, grade buttons, deck/card tiles, stats chips, forecast charts
- `test/` — SM-2 math, scheduler, database CRUD, export round-trip, review stats, study sessions, widget smoke tests

## License

MIT — see `LICENSE` if present, otherwise all rights reserved to the author.

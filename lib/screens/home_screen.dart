import 'package:material_ui/material_ui.dart';

import '../data/card_repository.dart';
import '../data/deck_repository.dart';
import '../data/stats_service.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../widgets/deck_form_dialog.dart';
import '../widgets/deck_tile.dart';
import '../widgets/due_summary_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/library_header.dart';
import 'about_screen.dart';
import 'deck_detail_screen.dart';
import 'import_export_screen.dart';
import 'review_history_screen.dart';
import 'search_screen.dart';
import 'stats_screen.dart';
import 'study_screen.dart';

/// Home: library overview (due today, streak, forecast) + deck list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _decks = DeckRepository();
  final _cards = CardRepository();
  final _stats = StatsService();

  List<Deck> _deckList = [];
  Map<String, DeckStats> _deckStats = {};
  LibraryStats? _libraryStats;
  List<Flashcard> _allCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await _decks.getAll();
    final stats = <String, DeckStats>{};
    for (final deck in decks) {
      stats[deck.id] = await _stats.deckStats(deck.id);
    }
    final library = await _stats.libraryStats(decks.length);
    final allCards = await _cards.getAll();
    if (!mounted) return;
    setState(() {
      _deckList = decks;
      _deckStats = stats;
      _libraryStats = library;
      _allCards = allCards;
      _loading = false;
    });
  }

  Future<void> _createDeck() async {
    final result = await showDeckFormDialog(context);
    if (result == null) return;
    await _decks.insert(Deck.create(
      name: result.name,
      description: result.description,
    ));
    await _load();
  }

  Future<void> _openDeck(Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeckDetailScreen(deck: deck),
      ),
    );
    await _load();
  }

  Future<void> _studyAllDue() async {
    final due = await _cards.getAllDue();
    if (!mounted) return;
    if (due.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudyScreen(
          title: 'All due cards',
          cards: due,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlashDeck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search cards',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SearchScreen(),
                ),
              );
              await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StatsScreen(),
                ),
              );
              await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Import / export',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ImportExportScreen(),
                ),
              );
              await _load();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'history') {
                _openHistory();
              } else if (value == 'about') {
                _openAbout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'history', child: Text('Review history')),
              PopupMenuItem(value: 'about', child: Text('About FlashDeck')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDeck,
        icon: const Icon(Icons.add),
        label: const Text('New deck'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _deckList.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 24),
                        EmptyState(
                          icon: Icons.style_outlined,
                          title: 'No decks yet',
                          message:
                              'Create your first deck, add some cards, and '
                              'FlashDeck will schedule your reviews with SM-2.',
                          actionLabel: 'Create a deck',
                          onAction: _createDeck,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_libraryStats != null)
                          LibraryHeader(
                            stats: _libraryStats!,
                            onStudyAll: _studyAllDue,
                          ),
                        const SizedBox(height: 16),
                        DueSummaryCard(cards: _allCards),
                        const SizedBox(height: 16),
                        Text(
                          'Your decks',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._deckList.map((deck) {
                          final stats = _deckStats[deck.id];
                          if (stats == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DeckTile(
                              deck: deck,
                              stats: stats,
                              onTap: () => _openDeck(deck),
                              onEdit: () => _renameDeck(deck),
                              onDelete: () => _deleteDeck(deck),
                            ),
                          );
                        }),
                        const SizedBox(height: 72),
                      ],
                    ),
            ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ReviewHistoryScreen(),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AboutScreen(),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _renameDeck(Deck deck) async {
    final result = await showDeckFormDialog(context, deck: deck);
    if (result == null) return;
    await _decks.update(deck.copyWith(
      name: result.name,
      description: result.description,
      updatedAt: DateTime.now(),
    ));
    await _load();
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${deck.name}"?'),
        content: const Text(
          'This deletes the deck and all of its cards and review history. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _decks.delete(deck.id);
    await _load();
  }
}

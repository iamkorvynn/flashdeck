import 'package:material_ui/material_ui.dart';

import '../data/card_repository.dart';
import '../data/deck_repository.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../widgets/empty_state.dart';
import 'card_editor_screen.dart';

/// Search across all cards by front/back text. Tapping a result
/// opens it in the editor.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _cards = CardRepository();
  final _decks = DeckRepository();
  final _controller = TextEditingController();

  List<Flashcard> _results = [];
  Map<String, Deck> _deckById = {};
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final results = await _cards.search(trimmed);
    final decks = await _decks.getAll();
    if (!mounted) return;
    setState(() {
      _results = results;
      _deckById = {for (final d in decks) d.id: d};
      _searched = true;
    });
  }

  Future<void> _openCard(Flashcard card) async {
    final deck = _deckById[card.deckId];
    if (deck == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => CardEditorScreen(deck: deck, card: card),
      ),
    );
    await _runSearch(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search cards')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search front or back…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _runSearch('');
                        },
                      ),
              ),
              onChanged: _runSearch,
              onSubmitted: _runSearch,
            ),
          ),
          Expanded(
            child: !_searched
                ? const EmptyState(
                    icon: Icons.search_outlined,
                    title: 'Search your cards',
                    message:
                        'Type to search across every deck — front and back.',
                  )
                : _results.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'No matches',
                        message: 'Try a different word or phrase.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final card = _results[index];
                          final deck = _deckById[card.deckId];
                          return Card(
                            child: ListTile(
                              title: Text(
                                card.front,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${deck?.name ?? 'Unknown deck'} · ${card.back}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                card.isNew
                                    ? 'New'
                                    : card.isDue
                                        ? 'Due'
                                        : 'Due ${card.dueAt.day}/${card.dueAt.month}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: card.isDue || card.isNew
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _openCard(card),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

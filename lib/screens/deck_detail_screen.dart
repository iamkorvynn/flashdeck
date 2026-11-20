import 'package:material_ui/material_ui.dart';

import '../data/card_repository.dart';
import '../data/deck_repository.dart';
import '../data/stats_service.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../widgets/card_tile.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_chip.dart';
import 'card_editor_screen.dart';
import 'study_screen.dart';

/// One deck: its cards, per-deck stats, add/edit/delete cards,
/// and the study entry point.
class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final _cards = CardRepository();
  final _decks = DeckRepository();
  final _stats = StatsService();

  Deck _deck = const Deck(
    id: '',
    name: '',
    description: '',
    createdAt: _epoch,
    updatedAt: _epoch,
  );
  static const _epoch = _EpochDate();

  List<Flashcard> _cardList = [];
  DeckStats? _deckStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _deck = widget.deck;
    _load();
  }

  Future<void> _load() async {
    final fresh = await _decks.getById(_deck.id);
    final cards = await _cards.getByDeck(_deck.id);
    final stats = await _stats.deckStats(_deck.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _deck = fresh;
      _cardList = cards;
      _deckStats = stats;
      _loading = false;
    });
  }

  Future<void> _addCard() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CardEditorScreen(deck: _deck),
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _editCard(Flashcard card) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CardEditorScreen(deck: _deck, card: card),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this card?',
      message: 'The card and its review history will be removed.',
    );
    if (!confirmed) return;
    await _cards.delete(card.id);
    await _load();
  }

  Future<void> _studyDue() async {
    final due = await _cards.getDueByDeck(_deck.id);
    if (!mounted) return;
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cards due in this deck right now.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudyScreen(
          title: _deck.name,
          cards: due,
        ),
      ),
    );
    await _load();
  }

  Future<void> _studyAll() async {
    if (_cardList.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudyScreen(
          title: '${_deck.name} — all cards',
          cards: List.of(_cardList),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _deckStats;
    return Scaffold(
      appBar: AppBar(
        title: Text(_deck.name),
        actions: [
          if (stats != null && stats.totalCards > 0)
            TextButton(
              onPressed: _studyAll,
              child: const Text('Study all'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _cardList.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 24),
                        EmptyState(
                          icon: Icons.credit_card_outlined,
                          title: 'No cards yet',
                          message:
                              'Add your first card — a question on the front, '
                              'the answer on the back.',
                          actionLabel: 'Add a card',
                          onAction: _addCard,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (stats != null) ...[
                          Row(
                            children: [
                              StatChip(
                                label: 'Cards',
                                value: '${stats.totalCards}',
                              ),
                              const SizedBox(width: 8),
                              StatChip(
                                label: 'Due',
                                value: '${stats.dueCards}',
                                color: stats.dueCards > 0
                                    ? theme.colorScheme.error
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              StatChip(
                                label: 'New',
                                value: '${stats.newCards}',
                              ),
                              const SizedBox(width: 8),
                              StatChip(
                                label: 'Learned',
                                value: '${stats.learnedCards}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  stats.dueCards == 0 ? null : _studyDue,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                stats.dueCards == 0
                                    ? 'Nothing due — come back later'
                                    : 'Study ${stats.dueCards} due card${stats.dueCards == 1 ? '' : 's'}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ..._cardList.map((card) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CardTile(
                              card: card,
                              onTap: () => _editCard(card),
                              onDelete: () => _deleteCard(card),
                            ),
                          );
                        }),
                        const SizedBox(height: 72),
                      ],
                    ),
            ),
    );
  }
}

/// Compile-time constant epoch used only as a placeholder deck value.
class _EpochDate extends DateTime {
  const _EpochDate() : super.fromMillisecondsSinceEpoch(0);
}

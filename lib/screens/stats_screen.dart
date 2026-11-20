import 'package:material_ui/material_ui.dart';

import '../data/card_repository.dart';
import '../data/deck_repository.dart';
import '../data/review_repository.dart';
import '../data/stats_service.dart';
import '../sm2/scheduler.dart';
import '../widgets/empty_state.dart';
import '../widgets/forecast_chart.dart';
import '../widgets/stat_chip.dart';

/// Library statistics: streak, retention, grade breakdown, forecast,
/// and per-deck retention.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _cards = CardRepository();
  final _decks = DeckRepository();
  final _reviews = ReviewRepository();
  final _stats = StatsService();

  LibraryStats? _library;
  Map<String, int> _grades = {};
  List<int> _forecast = [];
  List<({String name, double? retention, int total})> _perDeck = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await _decks.getAll();
    final library = await _stats.libraryStats(decks.length);
    final grades = await _reviews.gradeCounts();
    final cards = await _cards.getAll();
    final forecast = Scheduler.forecast(cards, 7);
    final perDeck = <({String name, double? retention, int total})>[];
    for (final deck in decks) {
      perDeck.add((
        name: deck.name,
        retention: await _reviews.retention(deckId: deck.id),
        total: await _reviews.totalReviews(deckId: deck.id),
      ));
    }
    if (!mounted) return;
    setState(() {
      _library = library;
      _grades = grades;
      _forecast = forecast;
      _perDeck = perDeck;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = _library;
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : library == null || library.totalCards == 0
              ? const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: 'No stats yet',
                  message:
                      'Add some cards and complete a study session — your '
                      'streak, retention and forecast will show up here.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          StatChip(
                            label: 'Day streak',
                            value: '${library.streak}',
                          ),
                          const SizedBox(width: 8),
                          StatChip(
                            label: 'Retention',
                            value: library.retention == null
                                ? '—'
                                : '${(library.retention! * 100).round()}%',
                          ),
                          const SizedBox(width: 8),
                          StatChip(
                            label: 'Reviews',
                            value: '${library.totalReviews}',
                          ),
                          const SizedBox(width: 8),
                          StatChip(
                            label: 'Learned',
                            value: '${library.learnedCards}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ForecastChart(forecast: _forecast),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grades given',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _GradeRow(
                                theme: theme,
                                label: 'Again',
                                count: _grades['again'] ?? 0,
                                color: const Color(0xFFD32F2F),
                              ),
                              _GradeRow(
                                theme: theme,
                                label: 'Hard',
                                count: _grades['hard'] ?? 0,
                                color: const Color(0xFFEF6C00),
                              ),
                              _GradeRow(
                                theme: theme,
                                label: 'Good',
                                count: _grades['good'] ?? 0,
                                color: const Color(0xFF2E7D32),
                              ),
                              _GradeRow(
                                theme: theme,
                                label: 'Easy',
                                count: _grades['easy'] ?? 0,
                                color: const Color(0xFF1565C0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Retention by deck',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_perDeck.isEmpty)
                                const Text('No decks yet.'),
                              ..._perDeck.map((d) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(d.name),
                                  subtitle: Text(
                                    d.total == 0
                                        ? 'No reviews yet'
                                        : '${d.total} review${d.total == 1 ? '' : 's'}',
                                  ),
                                  trailing: Text(
                                    d.retention == null
                                        ? '—'
                                        : '${(d.retention! * 100).round()}%',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int count;
  final Color color;

  const _GradeRow({
    required this.theme,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '$count',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

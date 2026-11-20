import 'package:material_ui/material_ui.dart';

import '../data/database_helper.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';

/// Recent review log: what was graded, when, and the grade given.
class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final _helper = DatabaseHelper.instance;
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT r.grade, r.quality, r.reviewed_at, r.interval_after,
             c.front, d.name AS deck_name
      FROM reviews r
      JOIN cards c ON c.id = r.card_id
      JOIN decks d ON d.id = r.deck_id
      ORDER BY r.reviewed_at DESC
      LIMIT 100
    ''');
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'again':
        return const Color(0xFFD32F2F);
      case 'hard':
        return const Color(0xFFEF6C00);
      case 'good':
        return const Color(0xFF2E7D32);
      case 'easy':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.history_outlined,
                  title: 'No reviews yet',
                  message:
                      'Complete a study session and your graded reviews '
                      'will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      final grade = row['grade'] as String;
                      final reviewedAt = DateTime.fromMillisecondsSinceEpoch(
                        row['reviewed_at'] as int,
                      );
                      final interval = row['interval_after'] as int;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _gradeColor(grade).withValues(alpha: 0.15),
                            child: Text(
                              grade[0].toUpperCase(),
                              style: TextStyle(
                                color: _gradeColor(grade),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            row['front'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${row['deck_name']} · '
                            '${formatShortDateTime(reviewedAt)}',
                          ),
                          trailing: Text(
                            '→ ${interval}d',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

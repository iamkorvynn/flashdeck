import 'package:material_ui/material_ui.dart';

import '../data/stats_service.dart';
import 'progress_ring.dart';
import 'stat_chip.dart';

/// Top of the home screen: greeting, due-today ring, streak and
/// a "Study all due" button.
class LibraryHeader extends StatelessWidget {
  final LibraryStats stats;
  final VoidCallback onStudyAll;

  const LibraryHeader({
    super.key,
    required this.stats,
    required this.onStudyAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learnedFraction = stats.totalCards == 0
        ? 0.0
        : stats.learnedCards / stats.totalCards;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProgressRing(
                  fraction: learnedFraction,
                  label: '${stats.dueCards}',
                  caption: 'due',
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.dueCards == 0
                            ? 'All caught up!'
                            : '${stats.dueCards} card${stats.dueCards == 1 ? '' : 's'} due today',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.totalCards} cards in ${stats.totalDecks} deck${stats.totalDecks == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: stats.dueCards == 0 ? null : onStudyAll,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Study all due'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatChip(
                  label: 'Day streak',
                  value: '${stats.streak}',
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'Learned',
                  value: '${stats.learnedCards}',
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'Retention',
                  value: stats.retention == null
                      ? '—'
                      : '${(stats.retention! * 100).round()}%',
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'Reviews',
                  value: '${stats.totalReviews}',
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

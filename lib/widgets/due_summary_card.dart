import 'package:material_ui/material_ui.dart';

import '../sm2/scheduler.dart';
import '../models/flashcard.dart';

/// "Due in the next 7 days" mini forecast strip.
class DueSummaryCard extends StatelessWidget {
  final List<Flashcard> cards;

  const DueSummaryCard({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = Scheduler.forecast(cards, 7);
    final max = forecast.fold<int>(1, (a, b) => a > b ? a : b);
    const labels = ['Today', 'Tom', '+2d', '+3d', '+4d', '+5d', '+6d'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming up — next 7 days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = forecast[i];
                final height = 8.0 + (count / max) * 56.0;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: i == 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

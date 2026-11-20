import 'package:material_ui/material_ui.dart';

/// Horizontal bar list: how many cards are due each day for the next
/// 7 days, with a total row.
class ForecastChart extends StatelessWidget {
  final List<int> forecast;

  const ForecastChart({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = [
      'Today',
      'Tomorrow',
      'In 2 days',
      'In 3 days',
      'In 4 days',
      'In 5 days',
      'In 6 days',
    ];
    final max = forecast.fold<int>(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due forecast — next 7 days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(forecast.length, (i) {
              final count = forecast[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        labels[i],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count / max,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

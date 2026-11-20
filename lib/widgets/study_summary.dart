import 'package:material_ui/material_ui.dart';

/// End-of-session card: how many reviewed, grade breakdown, and the
/// next due count. Shown when the study queue is finished.
class StudySummary extends StatelessWidget {
  final int reviewed;
  final int again;
  final int hard;
  final int good;
  final int easy;
  final VoidCallback onDone;

  const StudySummary({
    super.key,
    required this.reviewed,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = good + easy + hard;
    final retention = reviewed == 0 ? 0 : (passed / reviewed * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Session complete!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $reviewed card${reviewed == 1 ? '' : 's'} '
              'with $retention% recall.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Count(theme, 'Again', again, const Color(0xFFD32F2F)),
                const SizedBox(width: 16),
                _Count(theme, 'Hard', hard, const Color(0xFFEF6C00)),
                const SizedBox(width: 16),
                _Count(theme, 'Good', good, const Color(0xFF2E7D32)),
                const SizedBox(width: 16),
                _Count(theme, 'Easy', easy, const Color(0xFF1565C0)),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int value;
  final Color color;

  const _Count(this.theme, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

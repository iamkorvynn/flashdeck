import 'package:material_ui/material_ui.dart';

/// Circular progress ring with a centred label, e.g. "12 due".
class ProgressRing extends StatelessWidget {
  final double fraction;
  final String label;
  final String caption;
  final double size;

  const ProgressRing({
    super.key,
    required this.fraction,
    required this.label,
    required this.caption,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: 8,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

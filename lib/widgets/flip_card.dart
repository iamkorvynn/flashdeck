import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Tap-to-flip card used in study sessions. Shows [front] first;
/// tapping flips (3D-ish Y rotation) to reveal [back].
class FlipCard extends StatefulWidget {
  final String front;
  final String back;
  final String? hint;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.hint,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showingBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      _showingBack = !_showingBack;
      if (_showingBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: showBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _Face(
                      theme: theme,
                      text: widget.back,
                      label: 'Answer',
                      color: theme.colorScheme.secondaryContainer,
                      onColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                : _Face(
                    theme: theme,
                    text: widget.front,
                    label: 'Question',
                    color: theme.colorScheme.primaryContainer,
                    onColor: theme.colorScheme.onPrimaryContainer,
                    hint: widget.hint,
                  ),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  final ThemeData theme;
  final String text;
  final String label;
  final Color color;
  final Color onColor;
  final String? hint;

  const _Face({
    required this.theme,
    required this.text,
    required this.label,
    required this.color,
    required this.onColor,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: onColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: onColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 16, color: onColor.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

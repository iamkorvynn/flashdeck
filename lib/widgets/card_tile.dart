import 'package:material_ui/material_ui.dart';

import '../models/flashcard.dart';
import '../utils/dates.dart';

/// One flashcard row inside a deck: front, back preview and due state.
class CardTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueLabel = card.isNew
        ? 'New'
        : card.isDue
            ? 'Due now'
            : 'Due ${formatShortDate(card.dueAt)}';
    final dueColor = card.isDue || card.isNew
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          card.front,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          card.back,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dueColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dueLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: dueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Delete card',
            ),
          ],
        ),
      ),
    );
  }
}

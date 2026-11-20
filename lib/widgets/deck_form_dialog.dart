import 'package:material_ui/material_ui.dart';

import '../models/deck.dart';

/// Dialog for creating a new deck or renaming an existing one.
/// Returns the (name, description) pair, or null when cancelled.
class DeckFormDialog extends StatefulWidget {
  final Deck? deck;

  const DeckFormDialog({super.key, this.deck});

  @override
  State<DeckFormDialog> createState() => _DeckFormDialogState();
}

class _DeckFormDialogState extends State<DeckFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.deck?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.deck != null;
    return AlertDialog(
      title: Text(isEdit ? 'Rename deck' : 'New deck'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deck name',
                hintText: 'e.g. Biology — Cell Structure',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Give the deck a name';
                }
                if (value.trim().length > 80) {
                  return 'Keep the name under 80 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this deck for?',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
            ));
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

/// Shows the deck form and returns the entered values, or null.
Future<({String name, String description})?> showDeckFormDialog(
  BuildContext context, {
  Deck? deck,
}) {
  return showDialog<({String name, String description})>(
    context: context,
    builder: (context) => DeckFormDialog(deck: deck),
  );
}

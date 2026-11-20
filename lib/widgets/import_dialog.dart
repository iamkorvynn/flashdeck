import 'package:material_ui/material_ui.dart';

/// Dialog with a big text area for pasting a FlashDeck JSON export.
/// Returns the pasted text, or null when cancelled.
class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import from JSON'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 12,
          minLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste a FlashDeck export here…',
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop(text);
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}

/// Shows the import dialog and returns the pasted JSON, or null.
Future<String?> showImportDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const ImportDialog(),
  );
}

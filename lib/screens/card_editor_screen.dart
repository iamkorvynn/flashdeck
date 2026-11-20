import 'package:material_ui/material_ui.dart';

import '../data/card_repository.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

/// Create a new card or edit an existing one (front + back).
/// Returns true when the card was saved.
class CardEditorScreen extends StatefulWidget {
  final Deck deck;
  final Flashcard? card;

  const CardEditorScreen({super.key, required this.deck, this.card});

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cards = CardRepository();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _frontController =
        TextEditingController(text: widget.card?.front ?? '');
    _backController = TextEditingController(text: widget.card?.back ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    final existing = widget.card;
    if (existing == null) {
      await _cards.insert(Flashcard.create(
        deckId: widget.deck.id,
        front: front,
        back: back,
      ));
    } else {
      await _cards.update(existing.copyWith(
        front: front,
        back: back,
        updatedAt: DateTime.now(),
      ));
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit card' : 'New card'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Front — the question or prompt',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frontController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. What is the powerhouse of the cell?',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Write something on the front';
                }
                if (value.trim().length > 1000) {
                  return 'Keep the front under 1000 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Back — the answer',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 6,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. The mitochondria.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Write something on the back';
                }
                if (value.trim().length > 2000) {
                  return 'Keep the back under 2000 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (isEdit && widget.card!.reviewCount > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Reviewed ${widget.card!.reviewCount} time${widget.card!.reviewCount == 1 ? '' : 's'} · '
                    'interval ${widget.card!.intervalDays} day${widget.card!.intervalDays == 1 ? '' : 's'} · '
                    'ease ${widget.card!.easeFactor.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save changes' : 'Add card'),
            ),
          ],
        ),
      ),
    );
  }
}

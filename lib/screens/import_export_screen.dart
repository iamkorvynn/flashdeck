import 'package:material_ui/material_ui.dart';

import '../data/export_service.dart';
import '../widgets/import_dialog.dart';

/// Import/export: show the full-library JSON for copying elsewhere,
/// or paste a FlashDeck export to import it.
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _exporter = ExportService();
  String? _exportJson;
  bool _loadingExport = false;

  Future<void> _loadExport() async {
    setState(() => _loadingExport = true);
    final json = await _exporter.exportAll();
    if (!mounted) return;
    setState(() {
      _exportJson = json;
      _loadingExport = false;
    });
  }

  Future<void> _import() async {
    final text = await showImportDialog(context);
    if (text == null || !mounted) return;
    try {
      final result = await _exporter.importJson(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.decksImported} deck${result.decksImported == 1 ? '' : 's'} '
            'and ${result.cardsImported} card${result.cardsImported == 1 ? '' : 's'}.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import / export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exports every deck and card as JSON, including SM-2 '
                    'scheduling state. Copy it somewhere safe — it is your '
                    'backup.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _loadingExport ? null : _loadExport,
                        icon: const Icon(Icons.download),
                        label: const Text('Generate export'),
                      ),
                    ],
                  ),
                  if (_loadingExport) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  if (_exportJson != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _exportJson!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste a FlashDeck JSON export to add its decks and '
                    'cards to this device. Imported items get fresh ids, '
                    'so nothing you already have is overwritten.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _import,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import from JSON'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

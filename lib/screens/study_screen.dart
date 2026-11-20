import 'package:material_ui/material_ui.dart';

import '../models/flashcard.dart';
import '../models/review_grade.dart';
import '../study/study_session.dart';
import '../widgets/flip_card.dart';
import '../widgets/grade_buttons.dart';
import '../widgets/study_summary.dart';

/// Study session screen: flip the card, grade your recall.
/// Cards graded "Again" come back later in the same session.
class StudyScreen extends StatefulWidget {
  final String title;
  final List<Flashcard> cards;

  const StudyScreen({super.key, required this.title, required this.cards});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final StudySession _session;
  int _flipKey = 0;

  @override
  void initState() {
    super.initState();
    _session = StudySession(cards: widget.cards);
  }

  Future<void> _grade(ReviewGrade grade) async {
    await _session.grade(grade);
    setState(() => _flipKey += 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _session;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: session.isFinished
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: session.progress),
              ),
      ),
      body: session.isFinished
          ? StudySummary(
              reviewed: session.reviewedCount,
              again: session.againCount,
              hard: session.hardCount,
              good: session.goodCount,
              easy: session.easyCount,
              onDone: () => Navigator.of(context).pop(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Card ${session.reviewedCount + 1} of '
                        '${session.reviewedCount + session.remaining}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${session.remaining} left',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FlipCard(
                      key: ValueKey<int>(_flipKey),
                      front: session.current!.front,
                      back: session.current!.back,
                      hint: 'Tap to reveal the answer',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!session.revealed)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => setState(session.reveal),
                        child: const Text('Reveal answer'),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'How well did you remember it?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradeButtons(
                          onGrade: _grade,
                          intervals: session.intervalPreview(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

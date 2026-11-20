/// Self-graded recall quality for a flashcard review.
///
/// Maps onto the SM-2 quality scale (0-5):
/// - [again]: total blackout, quality 0
/// - [hard]: recalled with serious difficulty, quality 3
/// - [good]: recalled with some hesitation, quality 4
/// - [easy]: perfect recall, quality 5
enum ReviewGrade {
  again,
  hard,
  good,
  easy;

  /// SM-2 quality value (0-5) for this grade.
  int get quality {
    switch (this) {
      case ReviewGrade.again:
        return 0;
      case ReviewGrade.hard:
        return 3;
      case ReviewGrade.good:
        return 4;
      case ReviewGrade.easy:
        return 5;
    }
  }

  /// Short human label shown on the grade buttons.
  String get label {
    switch (this) {
      case ReviewGrade.again:
        return 'Again';
      case ReviewGrade.hard:
        return 'Hard';
      case ReviewGrade.good:
        return 'Good';
      case ReviewGrade.easy:
        return 'Easy';
    }
  }

  /// Whether the recall counted as a pass (SM-2 quality >= 3).
  bool get passed => quality >= 3;

  static ReviewGrade fromName(String name) => ReviewGrade.values
      .firstWhere((g) => g.name == name, orElse: () => ReviewGrade.good);
}

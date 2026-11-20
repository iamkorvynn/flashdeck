import '../utils/ids.dart';

/// A named collection of flashcards.
class Deck {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new deck with a fresh id and current timestamps.
  factory Deck.create({required String name, String description = ''}) {
    final now = DateTime.now();
    return Deck(
      id: newId(),
      name: name.trim(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Deck.fromMap(Map<String, Object?> map) {
    return Deck(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Deck copyWith({String? name, String? description, DateTime? updatedAt}) {
    return Deck(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

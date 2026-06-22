import 'package:uuid/uuid.dart';

import 'exercise.dart';

/// A daily workout program (e.g. "Push Day", "Leg Day").
class DayProgram {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  DayProgram({
    String? id,
    required this.name,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.archived = false,
  })  : id = id ?? const Uuid().v4(),
        exercises = exercises ?? <Exercise>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DayProgram copyWith({
    String? name,
    List<Exercise>? exercises,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return DayProgram(
      id: id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      archived: archived ?? this.archived,
    );
  }

  /// Clone used to recreate an old program as a new one.
  DayProgram duplicate() {
    return DayProgram(
      name: '$name (kopya)',
      exercises: exercises
          .map((e) => Exercise(
                name: e.name,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight,
                restSeconds: e.restSeconds,
                note: e.note,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'archived': archived,
      };

  factory DayProgram.fromJson(Map<String, dynamic> json) => DayProgram(
        id: json['id'] as String?,
        name: (json['name'] ?? 'Adsız Program') as String,
        exercises: ((json['exercises'] as List?) ?? [])
            .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        archived: json['archived'] as bool? ?? false,
      );
}

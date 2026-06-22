import 'package:uuid/uuid.dart';

/// A single exercise (full set: name, sets, reps, weight, rest, note).
class Exercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double? weight; // kg
  final int? restSeconds; // rest duration (seconds)
  final String? note;

  Exercise({
    String? id,
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.restSeconds,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    String? note,
    bool clearWeight = false,
    bool clearRest = false,
    bool clearNote = false,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: clearWeight ? null : (weight ?? this.weight),
      restSeconds: clearRest ? null : (restSeconds ?? this.restSeconds),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'restSeconds': restSeconds,
        'note': note,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String?,
        name: (json['name'] ?? '') as String,
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: (json['reps'] as num?)?.toInt() ?? 10,
        weight: (json['weight'] as num?)?.toDouble(),
        restSeconds: (json['restSeconds'] as num?)?.toInt(),
        note: json['note'] as String?,
      );

  /// Short summary for lists/exports: "4x10 · 60kg · 90sn".
  String get summary {
    final parts = <String>['$sets x $reps'];
    if (weight != null) parts.add('${formatNum(weight!)} kg');
    if (restSeconds != null) parts.add('${restSeconds}sn');
    return parts.join(' · ');
  }
}

/// Strips unnecessary decimals from a number (60.0 -> "60", 62.5 -> "62.5").
String formatNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

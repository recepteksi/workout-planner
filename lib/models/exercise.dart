import 'package:uuid/uuid.dart';

/// A single exercise. Fields are free text so real programs can be represented
/// faithfully (ranges like "8-15", supersets like "1+4", durations like
/// "35sn", "4000m", "30-45 sn").
class Exercise {
  final String id;
  final String name;
  final String sets;
  final String reps;
  final String? weight;
  final String? rest;
  final String? note; // e.g. section tag: Isınma / Core / Direnç / Esneme

  Exercise({
    String? id,
    required this.name,
    this.sets = '',
    this.reps = '',
    this.weight,
    this.rest,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Exercise copyWith({
    String? name,
    String? sets,
    String? reps,
    String? weight,
    String? rest,
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
      rest: clearRest ? null : (rest ?? this.rest),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'rest': rest,
        'note': note,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String?,
        name: (json['name'] ?? '') as String,
        sets: _str(json['sets']),
        reps: _str(json['reps']),
        weight: _strOrNull(json['weight']),
        // Older data stored rest as restSeconds (int).
        rest: _strOrNull(json['rest'] ?? json['restSeconds']),
        note: _strOrNull(json['note']),
      );

  static String _str(dynamic v) => v == null ? '' : v.toString();
  static String? _strOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Short summary for lists/exports: "4 x 8-15 · 60kg · 2 dk".
  String get summary {
    final p = <String>[];
    if (sets.isNotEmpty && reps.isNotEmpty) {
      p.add('$sets x $reps');
    } else if (sets.isNotEmpty) {
      p.add('$sets set');
    } else if (reps.isNotEmpty) {
      p.add(reps);
    }
    if ((weight ?? '').isNotEmpty) p.add(weight!);
    if ((rest ?? '').isNotEmpty) p.add(rest!);
    return p.join(' · ');
  }
}

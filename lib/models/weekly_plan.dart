import 'package:uuid/uuid.dart';

/// Days of the week (Monday=1 ... Sunday=7). Names are user-facing.
const weekdayNames = <int, String>{
  1: 'Pazartesi',
  2: 'Salı',
  3: 'Çarşamba',
  4: 'Perşembe',
  5: 'Cuma',
  6: 'Cumartesi',
  7: 'Pazar',
};

/// A single day assignment in a weekly plan: which day maps to which program.
class WeeklyEntry {
  final int weekday; // 1..7
  final String dayProgramId;

  WeeklyEntry({required this.weekday, required this.dayProgramId});

  String get weekdayName => weekdayNames[weekday] ?? '?';

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'dayProgramId': dayProgramId,
      };

  factory WeeklyEntry.fromJson(Map<String, dynamic> json) => WeeklyEntry(
        weekday: (json['weekday'] as num).toInt(),
        dayProgramId: json['dayProgramId'] as String,
      );
}

/// A weekly plan made up of 2-4 daily programs.
class WeeklyPlan {
  final String id;
  final String name;
  final List<WeeklyEntry> entries;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyPlan({
    String? id,
    required this.name,
    List<WeeklyEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        entries = entries ?? <WeeklyEntry>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WeeklyPlan copyWith({
    String? name,
    List<WeeklyEntry>? entries,
    DateTime? updatedAt,
  }) {
    return WeeklyPlan(
      id: id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) => WeeklyPlan(
        id: json['id'] as String?,
        name: (json['name'] ?? 'Adsız Hafta') as String,
        entries: ((json['entries'] as List?) ?? [])
            .map((e) =>
                WeeklyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

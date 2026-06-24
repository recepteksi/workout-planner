import 'exercise.dart';

/// A catalog exercise (from the bundled free-exercise-db library). Users drag
/// these into a program; [toExercise] fills in sensible default sets/reps.
class ExerciseTemplate {
  final String id;
  final String name;
  final String category; // strength, cardio, stretching, ...
  final String level; // beginner, intermediate, expert
  final String equipment; // barbell, dumbbell, body only, ...
  final List<String> primaryMuscles;
  final List<String> images; // relative paths within the CDN

  const ExerciseTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.equipment,
    required this.primaryMuscles,
    required this.images,
  });

  static const _cdnBase =
      'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises';

  /// Full URL of the first illustration, or null when none exists.
  String? get imageUrl =>
      images.isEmpty ? null : '$_cdnBase/${images.first}';

  /// Workout section tag stored on the created exercise's note, reusing the
  /// section system already used across the app (colored chips, etc.).
  String get section {
    switch (category) {
      case 'cardio':
        return 'Kardiyo';
      case 'stretching':
        return 'Esneme';
    }
    if (primaryMuscles.contains('abdominals')) return 'Karın';
    return 'Direnç';
  }

  /// Default sets prefilled when dragged into a program.
  String get defaultSets {
    switch (category) {
      case 'cardio':
      case 'stretching':
        return '';
      default:
        return '3';
    }
  }

  /// Default reps prefilled when dragged into a program.
  String get defaultReps {
    switch (category) {
      case 'cardio':
        return '15 dk';
      case 'stretching':
        return '30-45 sn';
      case 'plyometrics':
        return '12';
      default:
        return '8-12';
    }
  }

  Exercise toExercise() => Exercise(
        name: name,
        sets: defaultSets,
        reps: defaultReps,
        note: section,
      );

  /// Turkish labels for the primary muscles, for display and search.
  List<String> get muscleLabels =>
      primaryMuscles.map((m) => muscleTr[m] ?? m).toList();

  String get primaryMuscleLabel =>
      muscleLabels.isEmpty ? '' : muscleLabels.first;

  /// Lowercased text used for free-text search (English + Turkish terms).
  String get searchText => [
        name,
        equipment,
        category,
        ...primaryMuscles,
        ...muscleLabels,
      ].join(' ').toLowerCase();

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) =>
      ExerciseTemplate(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        level: (json['level'] ?? '') as String,
        equipment: (json['equipment'] ?? '') as String,
        primaryMuscles: ((json['primaryMuscles'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        images: ((json['images'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  /// English muscle key -> Turkish label.
  static const muscleTr = <String, String>{
    'abdominals': 'Karın',
    'hamstrings': 'Arka bacak',
    'adductors': 'İç bacak',
    'quadriceps': 'Ön bacak',
    'biceps': 'Biseps',
    'shoulders': 'Omuz',
    'chest': 'Göğüs',
    'middle back': 'Orta sırt',
    'calves': 'Baldır',
    'glutes': 'Kalça',
    'lower back': 'Bel',
    'lats': 'Sırt (kanat)',
    'triceps': 'Triseps',
    'traps': 'Trapez',
    'forearms': 'Önkol',
    'neck': 'Boyun',
    'abductors': 'Dış bacak',
  };
}

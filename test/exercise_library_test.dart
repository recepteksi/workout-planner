import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_planner/models/exercise_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled exercise library parses and produces sane defaults', () async {
    final raw = await rootBundle.loadString('assets/exercise_library.json');
    final list = (jsonDecode(raw) as List)
        .map((e) =>
            ExerciseTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    expect(list.length, greaterThan(500));

    // Every template yields a usable exercise with a section tag.
    for (final t in list) {
      expect(t.name, isNotEmpty);
      final ex = t.toExercise();
      expect(ex.name, t.name);
      expect(ex.section, isNotNull);
    }

    // Category-driven defaults.
    final stretch =
        list.firstWhere((t) => t.category == 'stretching');
    expect(stretch.defaultReps, '30-45 sn');
    expect(stretch.section, 'Esneme');

    final cardio = list.firstWhere((t) => t.category == 'cardio');
    expect(cardio.defaultReps, '15 dk');
    expect(cardio.section, 'Kardiyo');

    // Image URLs point at the CDN when present.
    final withImage = list.firstWhere((t) => t.images.isNotEmpty);
    expect(withImage.imageUrl, startsWith('https://cdn.jsdelivr.net/'));
  });
}

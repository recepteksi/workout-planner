import '../../models/exercise.dart';

/// Parses free text into exercises.
/// Example lines:
///   "Bench Press 4x10 60kg 90sn"
///   "1) Squat 5x5 @100"
///   "Şınav 3x12"
class TextParser {
  /// "sets x reps" — 4x10, 4X10, 4×10, 4*10
  static final _setsReps = RegExp(r'(\d+)\s*[xX×*]\s*(\d+)');

  /// weight: "60kg", "60 kg", "@100"
  static final _weightKg = RegExp(r'(\d+(?:[.,]\d+)?)\s*kg', caseSensitive: false);
  static final _weightAt = RegExp(r'@\s*(\d+(?:[.,]\d+)?)');

  /// rest: "90sn", "90 sn", "90 saniye", "2 dk", "2 dakika", "60 sec"
  static final _restSec =
      RegExp(r'(\d+)\s*(saniye|sn|sec|s)\b', caseSensitive: false);
  static final _restMin =
      RegExp(r'(\d+)\s*(dakika|dk|min)\b', caseSensitive: false);

  static final _leadingMarker = RegExp(r'^\s*([-•*]|\d+[.)])\s*');
  static final _headerLike = RegExp(
      r'^\s*(egzersiz|exercise|set|tekrar|reps?|a[ğg][ıi]rl[ıi]k|weight|hareket)\b',
      caseSensitive: false);

  static List<Exercise> parse(String text) {
    final result = <Exercise>[];
    for (final raw in text.split(RegExp(r'[\r\n]+'))) {
      final ex = parseLine(raw);
      if (ex != null) result.add(ex);
    }
    return result;
  }

  static Exercise? parseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return null;
    // Skip lines that look like a table header.
    if (_headerLike.hasMatch(line) && !_setsReps.hasMatch(line)) return null;

    line = line.replaceFirst(_leadingMarker, '');

    int sets = 3;
    int reps = 10;
    double? weight;
    int? rest;

    final sr = _setsReps.firstMatch(line);
    if (sr != null) {
      sets = int.tryParse(sr.group(1)!) ?? sets;
      reps = int.tryParse(sr.group(2)!) ?? reps;
      line = line.replaceRange(sr.start, sr.end, ' ');
    }

    final wKg = _weightKg.firstMatch(line);
    if (wKg != null) {
      weight = double.tryParse(wKg.group(1)!.replaceAll(',', '.'));
      line = line.replaceRange(wKg.start, wKg.end, ' ');
    } else {
      final wAt = _weightAt.firstMatch(line);
      if (wAt != null) {
        weight = double.tryParse(wAt.group(1)!.replaceAll(',', '.'));
        line = line.replaceRange(wAt.start, wAt.end, ' ');
      }
    }

    final rMin = _restMin.firstMatch(line);
    if (rMin != null) {
      rest = (int.tryParse(rMin.group(1)!) ?? 0) * 60;
      line = line.replaceRange(rMin.start, rMin.end, ' ');
    } else {
      final rSec = _restSec.firstMatch(line);
      if (rSec != null) {
        rest = int.tryParse(rSec.group(1)!);
        line = line.replaceRange(rSec.start, rSec.end, ' ');
      }
    }

    // Remaining text = exercise name; clean up separators.
    var name = line
        .replaceAll(RegExp(r'[\-:·|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty) name = 'Egzersiz';

    return Exercise(
      name: name,
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: rest,
    );
  }
}

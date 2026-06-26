import 'package:flutter_test/flutter_test.dart';
import 'package:workout_planner/services/exercise_image_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves catalog illustrations for known exercise names', () async {
    final resolver = await ExerciseImageResolver.load();

    String? url(String name) => resolver.resolve(name);
    final cdn = startsWith('https://cdn.jsdelivr.net/');

    // Exact (token-wise) matches.
    expect(url('Romanian deadlift'), cdn);
    expect(url('Leg press'), cdn);
    expect(url('Plank'), cdn);

    // Combos keep only the first variant: "A + B" / "A / B".
    expect(url('Cable face pull + Reverse pec deck'), cdn);
    expect(url('Squat (barbell / goblet)'), cdn);

    // Turkish qualifiers are ignored.
    expect(url('Pallof press (sağ + sol)'), cdn);

    // No confident match -> null (placeholder shown instead of a wrong image).
    expect(url('Bisiklet / yürüyüş'), isNull);
    expect(url('Cat-cow'), isNull);
    expect(url(''), isNull);
  });
}

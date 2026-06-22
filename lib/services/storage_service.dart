import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/day_program.dart';
import '../models/weekly_plan.dart';

/// Hive-based local storage. Uses IndexedDB on the web.
/// Each record is stored as a JSON string keyed by its id.
class StorageService {
  static const _programsBoxName = 'programs';
  static const _weeklyBoxName = 'weekly_plans';

  late final Box<String> _programsBox;
  late final Box<String> _weeklyBox;

  StorageService._();

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final service = StorageService._();
    service._programsBox = await Hive.openBox<String>(_programsBoxName);
    service._weeklyBox = await Hive.openBox<String>(_weeklyBoxName);
    // First run with no data: seed with the user's existing programs.
    if (service._programsBox.isEmpty) {
      await service._seedFromAsset();
    }
    return service;
  }

  Future<void> _seedFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/seed_programs.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isNotEmpty) await savePrograms(list);
    } catch (_) {
      // Seeding is best-effort; ignore if the asset is missing/invalid.
    }
  }

  // --- Daily programs ---

  List<DayProgram> loadPrograms() {
    return _programsBox.values
        .map((s) => DayProgram.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePrograms(List<DayProgram> programs) async {
    await _programsBox.clear();
    await _programsBox.putAll({
      for (final p in programs) p.id: jsonEncode(p.toJson()),
    });
  }

  // --- Weekly plans ---

  List<WeeklyPlan> loadWeeklyPlans() {
    return _weeklyBox.values
        .map((s) =>
            WeeklyPlan.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveWeeklyPlans(List<WeeklyPlan> plans) async {
    await _weeklyBox.clear();
    await _weeklyBox.putAll({
      for (final p in plans) p.id: jsonEncode(p.toJson()),
    });
  }
}

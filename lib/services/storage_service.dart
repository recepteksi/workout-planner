import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/day_program.dart';
import '../models/exercise.dart';
import '../models/weekly_plan.dart';

/// Hive-based local storage. Uses IndexedDB on the web.
/// Each record is stored as a JSON string keyed by its id.
class StorageService {
  static const _programsBoxName = 'programs';
  static const _weeklyBoxName = 'weekly_plans';
  static const _metaBoxName = 'meta';
  static const _absTag = 'Karın';

  late final Box<String> _programsBox;
  late final Box<String> _weeklyBox;
  late final Box<String> _metaBox;

  StorageService._();

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final service = StorageService._();
    service._programsBox = await Hive.openBox<String>(_programsBoxName);
    service._weeklyBox = await Hive.openBox<String>(_weeklyBoxName);
    service._metaBox = await Hive.openBox<String>(_metaBoxName);
    // First run with no data: seed with the user's existing programs.
    if (service._programsBox.isEmpty) {
      await service._seedFromAsset();
    }
    await service._migrateAbsToOwnProgram();
    await service._seedV2Programs();
    await service._seedV3Programs();
    return service;
  }

  /// One-time migration: pull the repeated "Karın" exercises out of every
  /// program and into a single standalone "Karın" program. Already-split data
  /// (fresh seeds) has no such exercises, so this is a no-op there.
  Future<void> _migrateAbsToOwnProgram() async {
    if (_metaBox.get('absSplitDone') == 'true') return;

    final programs = loadPrograms();
    // Collect a representative abs exercise per name (they repeat identically).
    final abs = <String, Exercise>{};
    for (final p in programs) {
      for (final e in p.exercises) {
        if (e.section == _absTag) {
          abs.putIfAbsent(e.name.toLowerCase(), () => e);
        }
      }
    }

    if (abs.isNotEmpty) {
      final next = <DayProgram>[];
      final hasAbsProgram =
          programs.any((p) => p.name.trim() == _absTag);
      if (!hasAbsProgram) {
        next.add(DayProgram(
          name: _absTag,
          exercises: abs.values
              .map((e) => Exercise(
                    name: e.name,
                    sets: e.sets,
                    reps: e.reps,
                    weight: e.weight,
                    rest: e.rest,
                    note: e.note,
                  ))
              .toList(),
        ));
      }
      for (final p in programs) {
        final stripped =
            p.exercises.where((e) => e.section != _absTag).toList();
        next.add(p.copyWith(exercises: stripped));
      }
      await savePrograms(next);
    }

    await _metaBox.put('absSplitDone', 'true');
  }

  /// One-time injection of the refreshed "Yeni" programs (güç + yağ yakım
  /// odaklı varyasyonlar). Adds any v2 program whose name isn't already
  /// present, so existing users get them without losing their old programs.
  Future<void> _seedV2Programs() async {
    if (_metaBox.get('v2ProgramsSeeded') == 'true') return;
    try {
      final raw = await rootBundle.loadString('assets/seed_programs_v2.json');
      final incoming = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final existing = loadPrograms();
      final existingNames =
          existing.map((p) => p.name.trim().toLowerCase()).toSet();
      final toAdd = incoming
          .where((p) => !existingNames.contains(p.name.trim().toLowerCase()))
          .toList();
      if (toAdd.isNotEmpty) {
        await savePrograms([...existing, ...toAdd]);
      }
    } catch (_) {
      // Best-effort; ignore if the asset is missing/invalid.
    }
    await _metaBox.put('v2ProgramsSeeded', 'true');
  }

  /// One-time injection of the chest-sparing programs ("Göğüs Dinlendirme").
  /// Adds any program whose name isn't already present, so existing users get
  /// them without losing their old programs.
  Future<void> _seedV3Programs() async {
    if (_metaBox.get('v3ProgramsSeeded') == 'true') return;
    try {
      final raw = await rootBundle.loadString('assets/seed_programs_v3.json');
      final incoming = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final existing = loadPrograms();
      final existingNames =
          existing.map((p) => p.name.trim().toLowerCase()).toSet();
      final toAdd = incoming
          .where((p) => !existingNames.contains(p.name.trim().toLowerCase()))
          .toList();
      if (toAdd.isNotEmpty) {
        await savePrograms([...existing, ...toAdd]);
      }
    } catch (_) {
      // Best-effort; ignore if the asset is missing/invalid.
    }
    await _metaBox.put('v3ProgramsSeeded', 'true');
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

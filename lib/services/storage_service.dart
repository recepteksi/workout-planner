import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/day_program.dart';
import '../models/exercise.dart';
import '../models/weekly_plan.dart';
import 'exercise_image_resolver.dart';

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
  late final ExerciseImageResolver _images;

  StorageService._();

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final service = StorageService._();
    service._programsBox = await Hive.openBox<String>(_programsBoxName);
    service._weeklyBox = await Hive.openBox<String>(_weeklyBoxName);
    service._metaBox = await Hive.openBox<String>(_metaBoxName);
    service._images = await ExerciseImageResolver.load();
    // First run with no data: seed with the user's existing programs.
    if (service._programsBox.isEmpty) {
      await service._seedFromAsset();
    }
    await service._migrateAbsToOwnProgram();
    await service._seedV2Programs();
    await service._seedV3Programs();
    // Backfill catalog illustrations onto any program exercises still missing
    // one (the seed programs were authored without image URLs).
    await service._backfillImages();
    // One-time reset: replace every program with the 3 newest programs, this
    // time with an illustration baked onto each exercise.
    await service._resetToV4Programs();
    // One-time reset: drop all programs and install the single "1. Gün" program
    // the user provided.
    await service._resetToV5Programs();
    return service;
  }

  /// Fills [Exercise.imageUrl] for every exercise that lacks one by matching its
  /// name against the catalog. Returns the same programs when nothing changed,
  /// preserving each program's [updatedAt] so list ordering is untouched.
  List<DayProgram> _withImages(List<DayProgram> programs) {
    return [
      for (final p in programs)
        p.copyWith(
          updatedAt: p.updatedAt,
          exercises: [
            for (final e in p.exercises)
              (e.imageUrl == null || e.imageUrl!.isEmpty)
                  ? () {
                      final url = _images.resolve(e.name);
                      return url == null ? e : e.copyWith(imageUrl: url);
                    }()
                  : e,
          ],
        ),
    ];
  }

  /// One-time backfill of illustrations onto already-stored programs (existing
  /// installs whose programs were seeded before images were carried over).
  Future<void> _backfillImages() async {
    if (_metaBox.get('imagesBackfilled') == 'true') return;
    final programs = loadPrograms();
    if (programs.isNotEmpty) {
      await savePrograms(_withImages(programs));
    }
    await _metaBox.put('imagesBackfilled', 'true');
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
        await savePrograms([...existing, ..._withImages(toAdd)]);
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
        await savePrograms([...existing, ..._withImages(toAdd)]);
      }
    } catch (_) {
      // Best-effort; ignore if the asset is missing/invalid.
    }
    await _metaBox.put('v3ProgramsSeeded', 'true');
  }

  /// One-time reset to the 3 newest programs ("Göğüs Dinlendirme" set), this
  /// time with an illustration baked onto every exercise in the seed JSON.
  /// Replaces ALL existing programs (the older ones were authored without
  /// images), per the user's request to recreate the last 3 with pictures and
  /// drop the rest. Guarded by a meta flag so a program created after the reset
  /// is never wiped on a later launch.
  Future<void> _resetToV4Programs() async {
    if (_metaBox.get('v4ResetDone') == 'true') return;
    try {
      final raw = await rootBundle.loadString('assets/seed_programs_v4.json');
      final incoming = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (incoming.isNotEmpty) {
        // Images are already embedded in the seed; _withImages only fills any
        // exercise the catalog still has no match for (e.g. "Leg swings").
        await savePrograms(_withImages(incoming));
      }
    } catch (_) {
      // Best-effort; ignore if the asset is missing/invalid.
    }
    await _metaBox.put('v4ResetDone', 'true');
  }

  /// One-time reset to the single program the user supplied ("1. Gün – Karın &
  /// İtiş"). Replaces ALL existing programs, per the user's request to drop the
  /// current ones and keep only this. Guarded by a meta flag so a program
  /// created after the reset is never wiped on a later launch.
  Future<void> _resetToV5Programs() async {
    if (_metaBox.get('v5ResetDone') == 'true') return;
    try {
      final raw = await rootBundle.loadString('assets/seed_programs_v5.json');
      final incoming = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (incoming.isNotEmpty) {
        // Images are embedded in the seed; _withImages only fills any exercise
        // the catalog still has no match for (e.g. "Bird Dog").
        await savePrograms(_withImages(incoming));
      }
    } catch (_) {
      // Best-effort; ignore if the asset is missing/invalid.
    }
    await _metaBox.put('v5ResetDone', 'true');
  }

  Future<void> _seedFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/seed_programs.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => DayProgram.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isNotEmpty) await savePrograms(_withImages(list));
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/weekly_plan.dart';
import '../services/storage_service.dart';

/// Overridden with the real StorageService in main.dart.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageServiceProvider must be overridden'),
);

/// All daily programs (including archived ones).
final programsProvider =
    NotifierProvider<ProgramsNotifier, List<DayProgram>>(ProgramsNotifier.new);

class ProgramsNotifier extends Notifier<List<DayProgram>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  List<DayProgram> build() {
    final list = _storage.loadPrograms();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void _commit(List<DayProgram> next) {
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = next;
    _storage.savePrograms(next);
  }

  DayProgram? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  void upsert(DayProgram program) {
    final next = [...state];
    final i = next.indexWhere((p) => p.id == program.id);
    if (i >= 0) {
      next[i] = program;
    } else {
      next.add(program);
    }
    _commit(next);
  }

  void delete(String id) {
    _commit(state.where((p) => p.id != id).toList());
  }

  void setArchived(String id, bool archived) {
    final p = byId(id);
    if (p == null) return;
    upsert(p.copyWith(archived: archived));
  }

  /// Clones an old program to recreate it, saves it, and returns the copy.
  DayProgram duplicate(String id) {
    final p = byId(id);
    final copy = (p ?? DayProgram(name: 'Yeni Program')).duplicate();
    upsert(copy);
    return copy;
  }
}

/// All weekly plans.
final weeklyPlansProvider =
    NotifierProvider<WeeklyPlansNotifier, List<WeeklyPlan>>(
        WeeklyPlansNotifier.new);

class WeeklyPlansNotifier extends Notifier<List<WeeklyPlan>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  List<WeeklyPlan> build() {
    final list = _storage.loadWeeklyPlans();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void _commit(List<WeeklyPlan> next) {
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = next;
    _storage.saveWeeklyPlans(next);
  }

  WeeklyPlan? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  void upsert(WeeklyPlan plan) {
    final next = [...state];
    final i = next.indexWhere((p) => p.id == plan.id);
    if (i >= 0) {
      next[i] = plan;
    } else {
      next.add(plan);
    }
    _commit(next);
  }

  void delete(String id) {
    _commit(state.where((p) => p.id != id).toList());
  }
}

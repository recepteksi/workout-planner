import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/weekly_plan.dart';
import '../providers/app_providers.dart';

/// Create/edit a weekly plan: pick 2-4 daily programs and assign them to days.
class WeeklyPlanEditorScreen extends ConsumerStatefulWidget {
  final WeeklyPlan? plan;
  const WeeklyPlanEditorScreen({super.key, this.plan});

  @override
  ConsumerState<WeeklyPlanEditorScreen> createState() =>
      _WeeklyPlanEditorScreenState();
}

class _WeeklyPlanEditorScreenState
    extends ConsumerState<WeeklyPlanEditorScreen> {
  late final TextEditingController _name;
  late final String _id;
  late final DateTime _createdAt;
  late List<WeeklyEntry> _entries;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _id = p?.id ?? WeeklyPlan(name: '').id;
    _name = TextEditingController(text: p?.name ?? '');
    _createdAt = p?.createdAt ?? DateTime.now();
    _entries = [...(p?.entries ?? const [])];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int _nextFreeWeekday() {
    final used = _entries.map((e) => e.weekday).toSet();
    for (var d = 1; d <= 7; d++) {
      if (!used.contains(d)) return d;
    }
    return 1;
  }

  void _addEntry(List<DayProgram> programs) {
    if (_entries.length >= 4) return;
    setState(() {
      _entries.add(WeeklyEntry(
        weekday: _nextFreeWeekday(),
        dayProgramId: programs.isNotEmpty ? programs.first.id : '',
      ));
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Lütfen bir hafta adı girin');
      return;
    }
    final valid = _entries.where((e) => e.dayProgramId.isNotEmpty).toList();
    if (valid.length < 2 || valid.length > 4) {
      _snack('2 ile 4 arasında program seçmelisiniz');
      return;
    }
    ref.read(weeklyPlansProvider.notifier).upsert(WeeklyPlan(
          id: _id,
          name: name,
          entries: valid,
          createdAt: _createdAt,
          updatedAt: DateTime.now(),
        ));
    Navigator.pop(context);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final programs =
        ref.watch(programsProvider).where((p) => !p.archived).toList();
    final isNew = widget.plan == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Yeni Haftalık Plan' : 'Haftalık Planı Düzenle'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: programs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Önce en az bir günlük program oluşturmalısınız.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Hafta adı',
                    hintText: 'ör. Push/Pull/Legs Haftası',
                  ),
                ),
                const SizedBox(height: 8),
                Text('Seçilen program: ${_entries.length}/4 (en az 2)',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                ..._entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _entryCard(i, programs);
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed:
                      _entries.length >= 4 ? null : () => _addEntry(programs),
                  icon: const Icon(Icons.add),
                  label: const Text('Gün ekle'),
                ),
              ],
            ),
    );
  }

  Widget _entryCard(int index, List<DayProgram> programs) {
    final entry = _entries[index];
    // Safe fallback if the selected program is no longer in the list (deleted).
    final selectedId = programs.any((p) => p.id == entry.dayProgramId)
        ? entry.dayProgramId
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<int>(
                initialValue: entry.weekday,
                decoration: const InputDecoration(labelText: 'Gün'),
                items: weekdayNames.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _entries[index] =
                      WeeklyEntry(weekday: v, dayProgramId: entry.dayProgramId));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Program'),
                items: programs
                    .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _entries[index] =
                      WeeklyEntry(weekday: entry.weekday, dayProgramId: v));
                },
              ),
            ),
            IconButton(
              tooltip: 'Kaldır',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _entries.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }
}

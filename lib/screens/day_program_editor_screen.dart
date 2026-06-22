import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/exercise.dart';
import '../providers/app_providers.dart';
import '../widgets/exercise_row.dart';
import '../widgets/page_container.dart';

/// Daily program create/edit screen.
/// If [program] is null, a new program is created.
class DayProgramEditorScreen extends ConsumerStatefulWidget {
  final DayProgram? program;
  const DayProgramEditorScreen({super.key, this.program});

  @override
  ConsumerState<DayProgramEditorScreen> createState() =>
      _DayProgramEditorScreenState();
}

class _DayProgramEditorScreenState
    extends ConsumerState<DayProgramEditorScreen> {
  late final TextEditingController _name;
  late List<Exercise> _exercises;
  late final String _id;
  late final DateTime _createdAt;
  late final bool _archived;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _id = p?.id ?? DayProgram(name: '').id;
    _name = TextEditingController(text: p?.name ?? '');
    _exercises = [...(p?.exercises ?? const [])];
    _createdAt = p?.createdAt ?? DateTime.now();
    _archived = p?.archived ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() => _exercises.add(Exercise(name: '')));
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir program adı girin')));
      return;
    }
    final cleaned =
        _exercises.where((e) => e.name.trim().isNotEmpty).toList();
    final program = DayProgram(
      id: _id,
      name: name,
      exercises: cleaned,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      archived: _archived,
    );
    ref.read(programsProvider.notifier).upsert(program);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.program == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Yeni Program' : 'Programı Düzenle'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Kaydet'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Program adı',
                    hintText: 'ör. İtiş Günü, Bacak Günü',
                  ),
                ),
              ),
              Expanded(
                child: _exercises.isEmpty
                    ? const EmptyState(
                        icon: Icons.add_task,
                        title: 'Henüz egzersiz yok',
                        subtitle: 'Alttaki "Egzersiz Ekle" ile başla.',
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                        itemCount: _exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _exercises[index];
                          return ExerciseRow(
                            key: ValueKey(ex.id),
                            index: index,
                            exercise: ex,
                            onChanged: (updated) =>
                                _exercises[index] = updated,
                            onDelete: () =>
                                setState(() => _exercises.removeAt(index)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Egzersiz Ekle'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/exercise.dart';
import '../models/exercise_template.dart';
import '../providers/app_providers.dart';
import '../widgets/exercise_grid_card.dart';
import '../widgets/exercise_library_panel.dart';
import '../widgets/page_container.dart';

/// Daily program create/edit screen.
/// If [program] is null, a new program is created.
///
/// Exercises are added by dragging (or tapping) cards from the bundled
/// exercise library, which prefills sensible default sets/reps.
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

  void _addTemplate(ExerciseTemplate t) {
    setState(() => _exercises.add(t.toExercise()));
  }

  Future<void> _editAt(int index) async {
    final updated = await showExerciseEditDialog(context, _exercises[index]);
    if (updated != null && index < _exercises.length) {
      setState(() => _exercises[index] = updated);
    }
  }

  void _moveExercise(int from, int to) {
    if (from == to) return;
    setState(() {
      final item = _exercises.removeAt(from);
      _exercises.insert(from < to ? to - 1 : to, item);
    });
  }

  void _openLibrarySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ExerciseLibraryPanel(
            onPick: (t) {
              _addTemplate(t);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  duration: const Duration(milliseconds: 700),
                  content: Text('${t.name} eklendi')));
            },
          ),
        ),
      ),
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Program adı',
                  hintText: 'ör. İtiş Günü, Bacak Günü',
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _LabeledPane(
                            title: 'Egzersiz Kütüphanesi',
                            icon: Icons.photo_library_outlined,
                            child: ExerciseLibraryPanel(onPick: _addTemplate),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: _LabeledPane(
                            title: 'Program (${_exercises.length})',
                            icon: Icons.list_alt,
                            child: _programList(dropTarget: true),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _programList(dropTarget: false);
              },
            ),
          ),
        ],
      ),
      // On wide screens the library lives in the left pane (drag to add); on
      // narrow screens a FAB opens it as a sheet.
      floatingActionButton: LayoutBuilder(
        builder: (context, _) {
          final wide = MediaQuery.of(context).size.width >= 900;
          if (wide) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _openLibrarySheet,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Kütüphaneden Ekle'),
          );
        },
      ),
    );
  }

  Widget _programList({required bool dropTarget}) {
    final list = _exercises.isEmpty
        ? EmptyState(
            icon: Icons.add_task,
            title: 'Henüz egzersiz yok',
            subtitle: dropTarget
                ? 'Soldaki kütüphaneden egzersiz kartlarını buraya sürükle.'
                : 'Alttaki "Kütüphaneden Ekle" ile başla.',
          )
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 210,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              final ex = _exercises[index];
              final card = ExerciseGridCard(
                index: index,
                exercise: ex,
                onTap: () => _editAt(index),
                onDelete: () => setState(() => _exercises.removeAt(index)),
              );
              // Drag a card onto another to reorder (long-press to start).
              return DragTarget<int>(
                onWillAcceptWithDetails: (d) => d.data != index,
                onAcceptWithDetails: (d) => _moveExercise(d.data, index),
                builder: (context, candidate, rejected) {
                  final hovering = candidate.isNotEmpty;
                  return LongPressDraggable<int>(
                    key: ValueKey(ex.id),
                    data: index,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(width: 190, height: 210, child: card),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: card),
                    child: AnimatedScale(
                      scale: hovering ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: card,
                    ),
                  );
                },
              );
            },
          );

    if (!dropTarget) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: list,
        ),
      );
    }

    return DragTarget<ExerciseTemplate>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _addTemplate(d.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final scheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering ? scheme.primary : Colors.transparent,
              width: 2,
            ),
            color: hovering
                ? scheme.primaryContainer.withValues(alpha: 0.15)
                : null,
          ),
          child: list,
        );
      },
    );
  }
}

/// A titled container for the editor's two panes.
class _LabeledPane extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _LabeledPane(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import 'section_colors.dart';

/// A single exercise shown as a square card in the program editor grid,
/// mirroring the look of the exercise library cards. Tinted by the exercise's
/// section (body region) tag. Tap to edit, X to remove.
class ExerciseGridCard extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExerciseGridCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final section = exercise.section;
    final color = sectionColor(section);
    final name = exercise.name.trim();

    final chips = <String>[];
    final sets = exercise.sets.trim();
    final reps = exercise.reps.trim();
    if (sets.isNotEmpty && reps.isNotEmpty) {
      chips.add('$sets x $reps');
    } else if (sets.isNotEmpty) {
      chips.add('$sets set');
    } else if (reps.isNotEmpty) {
      chips.add(reps);
    }
    if ((exercise.weight ?? '').trim().isNotEmpty) chips.add(exercise.weight!.trim());
    if ((exercise.rest ?? '').trim().isNotEmpty) chips.add(exercise.rest!.trim());

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored header: order badge + section tag + remove.
            Container(
              color: color.withValues(alpha: 0.12),
              padding: const EdgeInsets.fromLTRB(8, 5, 2, 5),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: color,
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      section ?? 'Diğer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Çıkar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 28, height: 28),
                    icon: Icon(Icons.close,
                        size: 16, color: scheme.onSurfaceVariant),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            // Body: name + stat chips.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Yeni egzersiz' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: name.isEmpty ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    const Spacer(),
                    if (chips.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [for (final c in chips) _chip(c, color)],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Opens the edit sheet for [exercise]; resolves to the edited copy, or null
/// if the user dismissed it without saving.
Future<Exercise?> showExerciseEditSheet(
    BuildContext context, Exercise exercise) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _ExerciseEditSheet(exercise: exercise),
    ),
  );
}

class _ExerciseEditSheet extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseEditSheet({required this.exercise});

  @override
  State<_ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<_ExerciseEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late final TextEditingController _rest;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _name = TextEditingController(text: e.name);
    _sets = TextEditingController(text: e.sets);
    _reps = TextEditingController(text: e.reps);
    _weight = TextEditingController(text: e.weight ?? '');
    _rest = TextEditingController(text: e.rest ?? '');
    _note = TextEditingController(text: e.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    _rest.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _currentSection {
    final n = _note.text.trim();
    if (n.isEmpty) return null;
    final i = n.indexOf('·');
    final s = (i >= 0 ? n.substring(0, i) : n).trim();
    return s.isEmpty ? null : s;
  }

  /// Set the leading section word while preserving any "· qualifier" suffix.
  void _setSection(String section) {
    final n = _note.text.trim();
    final i = n.indexOf('·');
    final rest = i >= 0 ? n.substring(i) : '';
    _note.text = rest.isEmpty ? section : '$section $rest'.trim();
    setState(() {});
  }

  void _save() {
    final w = _weight.text.trim();
    final r = _rest.text.trim();
    final n = _note.text.trim();
    Navigator.pop(
      context,
      widget.exercise.copyWith(
        name: _name.text.trim(),
        sets: _sets.text.trim(),
        reps: _reps.text.trim(),
        weight: w.isEmpty ? null : w,
        rest: r.isEmpty ? null : r,
        note: n.isEmpty ? null : n,
        clearWeight: w.isEmpty,
        clearRest: r.isEmpty,
        clearNote: n.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentSection;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Egzersizi düzenle',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                autofocus: widget.exercise.name.trim().isEmpty,
                decoration: const InputDecoration(
                    labelText: 'Egzersiz', border: OutlineInputBorder()),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_sets, 'Set')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_reps, 'Tekrar')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_weight, 'Ağırlık')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_rest, 'Dinlenme')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Bölüm (vücut bölgesi)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final s in sectionColors.keys)
                    ChoiceChip(
                      label: Text(s),
                      selected: current == s,
                      visualDensity: VisualDensity.compact,
                      selectedColor: sectionColor(s).withValues(alpha: 0.18),
                      onSelected: (_) => _setSection(s),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_note, 'Bölüm / Not (serbest)'),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}

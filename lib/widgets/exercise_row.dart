import 'package:flutter/material.dart';

import '../models/exercise.dart';

/// A single editable exercise row. Calls [onChanged] on every change.
class ExerciseRow extends StatefulWidget {
  final int index;
  final Exercise exercise;
  final ValueChanged<Exercise> onChanged;
  final VoidCallback onDelete;

  const ExerciseRow({
    super.key,
    required this.index,
    required this.exercise,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<ExerciseRow> {
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

  void _emit() {
    final w = _weight.text.trim();
    final r = _rest.text.trim();
    final n = _note.text.trim();
    widget.onChanged(widget.exercise.copyWith(
      name: _name.text.trim(),
      sets: _sets.text.trim(),
      reps: _reps.text.trim(),
      weight: w.isEmpty ? null : w,
      rest: r.isEmpty ? null : r,
      note: n.isEmpty ? null : n,
      clearWeight: w.isEmpty,
      clearRest: r.isEmpty,
      clearNote: n.isEmpty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Egzersiz'),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  tooltip: 'Sil',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _field(_sets, 'Set', 80),
                _field(_reps, 'Tekrar', 110),
                _field(_weight, 'Ağırlık', 110),
                _field(_rest, 'Dinlenme', 120),
                _field(_note, 'Bölüm / Not', 200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, double width) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _emit(),
      ),
    );
  }
}

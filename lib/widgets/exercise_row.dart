import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    _sets = TextEditingController(text: '${e.sets}');
    _reps = TextEditingController(text: '${e.reps}');
    _weight = TextEditingController(text: e.weight == null ? '' : formatNum(e.weight!));
    _rest = TextEditingController(text: e.restSeconds?.toString() ?? '');
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
    final weightText = _weight.text.trim().replaceAll(',', '.');
    final restText = _rest.text.trim();
    final noteText = _note.text.trim();
    widget.onChanged(widget.exercise.copyWith(
      name: _name.text.trim(),
      sets: int.tryParse(_sets.text.trim()) ?? widget.exercise.sets,
      reps: int.tryParse(_reps.text.trim()) ?? widget.exercise.reps,
      weight: weightText.isEmpty ? null : double.tryParse(weightText),
      restSeconds: restText.isEmpty ? null : int.tryParse(restText),
      note: noteText.isEmpty ? null : noteText,
      clearWeight: weightText.isEmpty,
      clearRest: restText.isEmpty,
      clearNote: noteText.isEmpty,
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
                _numField(_sets, 'Set', 64),
                _numField(_reps, 'Tekrar', 72),
                _numField(_weight, 'Ağırlık (kg)', 110, allowDecimal: true),
                _numField(_rest, 'Dinlenme (sn)', 120),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _note,
                    decoration: const InputDecoration(labelText: 'Not'),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label, double width,
      {bool allowDecimal = false}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
        ],
        onChanged: (_) => _emit(),
      ),
    );
  }
}

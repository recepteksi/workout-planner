import 'package:flutter/material.dart';

import '../models/exercise.dart';
import 'section_colors.dart';

/// A single editable exercise, shown as a compact card. Collapsed it only
/// shows the name + a one-line summary; tapping expands the edit fields. The
/// left edge is tinted by the exercise's section (body region) tag.
/// Calls [onChanged] on every change.
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

  late bool _expanded;

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
    // New/blank exercises open ready to edit; existing ones start collapsed.
    _expanded = e.name.trim().isEmpty;
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

  /// Re-emit and rebuild so the header (name, summary, color) stays in sync
  /// while editing.
  void _onEdited() => setState(_emit);

  /// Section tag = text before any " · " qualifier in the note.
  String? get _section {
    final n = _note.text.trim();
    if (n.isEmpty) return null;
    final i = n.indexOf('·');
    final s = (i >= 0 ? n.substring(0, i) : n).trim();
    return s.isEmpty ? null : s;
  }

  String get _summary {
    final p = <String>[];
    final s = _sets.text.trim();
    final r = _reps.text.trim();
    if (s.isNotEmpty && r.isNotEmpty) {
      p.add('$s x $r');
    } else if (s.isNotEmpty) {
      p.add('$s set');
    } else if (r.isNotEmpty) {
      p.add(r);
    }
    if (_weight.text.trim().isNotEmpty) p.add(_weight.text.trim());
    if (_rest.text.trim().isNotEmpty) p.add(_rest.text.trim());
    return p.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final section = _section;
    final color = sectionColor(section);
    final name = _name.text.trim();
    final summary = _summary;
    final subtitle = [
      ?section,
      if (summary.isNotEmpty) summary,
    ].join('  ·  ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text('${widget.index + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Yeni egzersiz' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: name.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          if (!_expanded && subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20, color: scheme.onSurfaceVariant),
                    IconButton(
                      tooltip: 'Sil',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'Egzersiz', isDense: true),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _onEdited(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _field(_sets, 'Set', 70),
                        _field(_reps, 'Tekrar', 100),
                        _field(_weight, 'Ağırlık', 100),
                        _field(_rest, 'Dinlenme', 110),
                        _field(_note, 'Bölüm / Not', 180),
                      ],
                    ),
                  ],
                ),
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
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (_) => _onEdited(),
      ),
    );
  }
}

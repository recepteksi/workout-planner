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
            // Illustration with the order badge, section tag and remove
            // button overlaid on top.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExerciseThumb(url: exercise.imageUrl),
                  // Scrim so the overlaid controls stay legible on any image.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x66000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 6,
                    right: 2,
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
                        const Spacer(),
                        Material(
                          color: Colors.black26,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onDelete,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            const BorderRadius.only(topRight: Radius.circular(8)),
                      ),
                      child: Text(
                        section ?? 'Diğer',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer: name + stat chips.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Egzersiz seç' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: name.isEmpty ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [for (final c in chips) _chip(c, color)],
                    ),
                  ],
                ],
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

/// Network thumbnail for an exercise illustration with a graceful
/// loading/error placeholder. Decodes at a small size so a grid of these
/// doesn't exhaust memory on web (CanvasKit).
class ExerciseThumb extends StatelessWidget {
  final String? url;
  const ExerciseThumb({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      cacheWidth: 360,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

/// Opens the centered edit dialog for [exercise]; resolves to the edited copy,
/// or null if the user dismissed it without saving. A dialog (rather than a
/// bottom sheet) suits the web/desktop target this app ships to.
Future<Exercise?> showExerciseEditDialog(
    BuildContext context, Exercise exercise) {
  return showDialog<Exercise>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: _ExerciseEditForm(exercise: exercise),
    ),
  );
}

class _ExerciseEditForm extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseEditForm({required this.exercise});

  @override
  State<_ExerciseEditForm> createState() => _ExerciseEditFormState();
}

class _ExerciseEditFormState extends State<_ExerciseEditForm> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late final TextEditingController _rest;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _sets = TextEditingController(text: e.sets);
    _reps = TextEditingController(text: e.reps);
    _weight = TextEditingController(text: e.weight ?? '');
    _rest = TextEditingController(text: e.rest ?? '');
    _note = TextEditingController(text: e.note ?? '');
  }

  @override
  void dispose() {
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
    final scheme = Theme.of(context).colorScheme;
    final current = _currentSection;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image banner with the (read-only) exercise name and a close
          // button overlaid. The name comes only from the library pick.
          SizedBox(
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExerciseThumb(url: widget.exercise.imageUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black38,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Text(
                    widget.exercise.name.trim().isEmpty
                        ? 'Egzersiz'
                        : widget.exercise.name.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text('Bölüm (vücut bölgesi)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant)),
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
                          selectedColor:
                              sectionColor(s).withValues(alpha: 0.18),
                          onSelected: (_) => _setSection(s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_note, 'Bölüm / Not (serbest)'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Tamam'),
                ),
              ],
            ),
          ),
        ],
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

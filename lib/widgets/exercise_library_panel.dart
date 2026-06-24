import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise_template.dart';
import '../providers/app_providers.dart';

/// A searchable, filterable grid of catalog exercises. Each card can be
/// dragged into a program or tapped to add it directly.
class ExerciseLibraryPanel extends ConsumerStatefulWidget {
  /// Called when an exercise is tapped (or its add button pressed).
  final ValueChanged<ExerciseTemplate> onPick;

  const ExerciseLibraryPanel({super.key, required this.onPick});

  @override
  ConsumerState<ExerciseLibraryPanel> createState() =>
      _ExerciseLibraryPanelState();
}

class _ExerciseLibraryPanelState extends ConsumerState<ExerciseLibraryPanel> {
  String _query = '';
  String? _muscle; // English muscle key, null = all

  // Common muscle groups shown as filter chips, in a sensible order.
  static const _muscleFilters = [
    'abdominals',
    'chest',
    'shoulders',
    'lats',
    'middle back',
    'biceps',
    'triceps',
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exerciseLibraryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            hintText: 'Egzersiz ara (örn. squat, göğüs, biceps)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('Tümü', null),
              for (final m in _muscleFilters)
                _filterChip(ExerciseTemplate.muscleTr[m] ?? m, m),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Kütüphane yüklenemedi: $e')),
            data: (all) {
              final items = all.where((t) {
                if (_muscle != null && !t.primaryMuscles.contains(_muscle)) {
                  return false;
                }
                if (_query.isEmpty) return true;
                return t.searchText.contains(_query);
              }).toList();

              if (items.isEmpty) {
                return const Center(child: Text('Eşleşen egzersiz yok'));
              }
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 196,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _card(items[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? muscle) {
    final selected = _muscle == muscle;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _muscle = selected ? null : muscle),
      ),
    );
  }

  Widget _card(ExerciseTemplate t) {
    final card = _ExerciseTemplateCard(
      template: t,
      onTap: () => widget.onPick(t),
    );
    return Draggable<ExerciseTemplate>(
      data: t,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _dragFeedback(t),
      child: card,
    );
  }

  Widget _dragFeedback(ExerciseTemplate t) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: scheme.onPrimary, size: 18),
            const SizedBox(width: 6),
            Text(t.name,
                style: TextStyle(
                    color: scheme.onPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Visual card for a single catalog exercise (image, name, muscle, default).
class _ExerciseTemplateCard extends StatelessWidget {
  final ExerciseTemplate template;
  final VoidCallback onTap;

  const _ExerciseTemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaults = [template.defaultSets, template.defaultReps]
        .where((s) => s.isNotEmpty)
        .join(' x ');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ExerciseImage(url: template.imageUrl)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.primaryMuscleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                      ),
                      if (defaults.isNotEmpty)
                        Text(defaults,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary)),
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
}

/// Network image with a graceful loading/error placeholder.
class _ExerciseImage extends StatelessWidget {
  final String? url;
  const _ExerciseImage({this.url});

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
    // Decode at thumbnail resolution. The source images are 750x500; decoding
    // hundreds of them at full size exhausts memory on web (CanvasKit) and
    // white-screens the tab. Cards are ~180px wide, so ~360px is plenty.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/weekly_plan.dart';
import '../providers/app_providers.dart';
import '../services/export/excel_exporter.dart';
import '../services/export/pdf_exporter.dart';
import '../widgets/page_container.dart';
import '../widgets/program_card.dart';
import 'day_program_editor_screen.dart';
import 'import_screen.dart';

/// Single-page dashboard: a program library (cards) on one side and a
/// drag-and-drop weekly board on the other. Programs are dragged from the
/// library onto the week, and reordered inside the week by dragging.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showArchived = false;

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // --- Weekly board helpers ---

  WeeklyPlan _currentPlan() {
    final plans = ref.read(weeklyPlansProvider);
    return plans.isNotEmpty ? plans.first : WeeklyPlan(name: 'Haftalık Plan');
  }

  void _saveEntries(List<WeeklyEntry> entries) {
    final base = _currentPlan();
    final normalized = [
      for (var i = 0; i < entries.length; i++)
        WeeklyEntry(weekday: i + 1, dayProgramId: entries[i].dayProgramId),
    ];
    ref
        .read(weeklyPlansProvider.notifier)
        .upsert(base.copyWith(entries: normalized));
  }

  void _addToWeek(String programId) {
    final entries = [..._currentPlan().entries];
    if (entries.length >= 7) {
      _snack('Bir haftada en fazla 7 gün olabilir');
      return;
    }
    entries.add(WeeklyEntry(weekday: entries.length + 1, dayProgramId: programId));
    _saveEntries(entries);
  }

  void _removeFromWeek(int index) {
    final entries = [..._currentPlan().entries]..removeAt(index);
    _saveEntries(entries);
  }

  void _reorderWeek(int oldIndex, int newIndex) {
    final entries = [..._currentPlan().entries];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = entries.removeAt(oldIndex);
    entries.insert(newIndex, item);
    _saveEntries(entries);
  }

  Future<void> _guarded(Future<void> Function() action, String okMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final programs = ref.watch(programsProvider);
    final plans = ref.watch(weeklyPlansProvider);
    final plan = plans.isNotEmpty ? plans.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: scheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text('Antrenman Programı'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => _push(const ImportScreen()),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('İçe Aktar'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final library = _libraryPanel(programs);
          final week = _weekPanel(plan, programs);

          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: library),
                  const SizedBox(width: 16),
                  SizedBox(width: 420, child: week),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 420, child: library),
                const SizedBox(height: 16),
                SizedBox(height: 460, child: week),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(const DayProgramEditorScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Program'),
      ),
    );
  }

  // --- Library panel ---

  Widget _libraryPanel(List<DayProgram> programs) {
    final scheme = Theme.of(context).colorScheme;
    final active = programs.where((p) => !p.archived).toList();
    final archived = programs.where((p) => p.archived).toList();
    final visible = _showArchived ? archived : active;

    return _Panel(
      title: 'Programlarım',
      icon: Icons.grid_view_rounded,
      trailing: archived.isEmpty
          ? null
          : SegmentedButton<bool>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment(value: false, label: Text('Aktif (${active.length})')),
                ButtonSegment(
                    value: true, label: Text('Arşiv (${archived.length})')),
              ],
              selected: {_showArchived},
              onSelectionChanged: (s) =>
                  setState(() => _showArchived = s.first),
            ),
      child: visible.isEmpty
          ? EmptyState(
              icon: _showArchived ? Icons.archive_outlined : Icons.fitness_center,
              title: _showArchived ? 'Arşiv boş' : 'Henüz program yok',
              subtitle: _showArchived
                  ? 'Arşivlediğin programlar burada görünür.'
                  : 'Sağ alttaki "Yeni Program" ile başla. Kartı haftaya sürükleyebilirsin.',
            )
          : GridView.builder(
              padding: const EdgeInsets.only(bottom: 96, top: 4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 168,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final p = visible[i];
                final card = ProgramCard(
                  program: p,
                  onEdit: () => _push(DayProgramEditorScreen(program: p)),
                  onAddToWeek: () => _addToWeek(p.id),
                );
                return Draggable<String>(
                  data: p.id,
                  feedback: _dragFeedback(p, scheme),
                  childWhenDragging: Opacity(opacity: 0.4, child: card),
                  child: card,
                );
              },
            ),
    );
  }

  Widget _dragFeedback(DayProgram p, ColorScheme scheme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.drag_indicator, color: scheme.onPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: scheme.onPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Week panel ---

  Widget _weekPanel(WeeklyPlan? plan, List<DayProgram> programs) {
    final scheme = Theme.of(context).colorScheme;
    final byId = {for (final p in programs) p.id: p};
    final entries = plan?.entries ?? const <WeeklyEntry>[];

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _addToWeek(d.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return _Panel(
          title: 'Haftalık Plan',
          icon: Icons.calendar_view_week,
          highlight: hovering,
          trailing: entries.isEmpty
              ? null
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (v) async {
                    final p = plan!;
                    switch (v) {
                      case 'pdf':
                        await _guarded(
                            () => PdfExporter.exportWeeklyPlan(p, programs),
                            'PDF hazırlandı');
                        break;
                      case 'excel':
                        await _guarded(
                            () => ExcelExporter.exportWeeklyPlan(p, programs),
                            'Excel indirildi');
                        break;
                      case 'clear':
                        _saveEntries([]);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                            leading: Icon(Icons.picture_as_pdf),
                            title: Text('PDF dışa aktar'))),
                    PopupMenuItem(
                        value: 'excel',
                        child: ListTile(
                            leading: Icon(Icons.table_chart),
                            title: Text('Excel dışa aktar'))),
                    PopupMenuDivider(),
                    PopupMenuItem(
                        value: 'clear',
                        child: ListTile(
                            leading: Icon(Icons.clear_all),
                            title: Text('Haftayı temizle'))),
                  ],
                ),
          child: entries.isEmpty
              ? _dropHint(hovering, scheme)
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  itemCount: entries.length,
                  onReorder: _reorderWeek,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final prog = byId[e.dayProgramId];
                    return _dayTile(i, prog, key: ValueKey('$i-${e.dayProgramId}'));
                  },
                ),
        );
      },
    );
  }

  Widget _dropHint(bool hovering, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: hovering
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hovering ? scheme.primary : scheme.outlineVariant,
          width: hovering ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.drag_indicator,
              size: 36,
              color: hovering ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'Programları buraya sürükle',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hovering ? scheme.primary : scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text('Sıralamak için günleri sürükle-bırak yap',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _dayTile(int index, DayProgram? prog, {required Key key}) {
    final scheme = Theme.of(context).colorScheme;
    final dayName = weekdayNames[index + 1] ?? 'Gün ${index + 1}';
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator,
                    color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dayName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(prog?.name ?? 'Silinmiş program',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (prog != null)
                      Text('${prog.exercises.length} egzersiz',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Kaldır',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeFromWeek(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled panel container used for both the library and the week board.
class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool highlight;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: highlight ? scheme.primary : scheme.outlineVariant,
            width: highlight ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

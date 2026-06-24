import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../providers/app_providers.dart';
import '../services/export/excel_exporter.dart';
import '../services/export/pdf_exporter.dart';
import 'section_colors.dart';

/// A program shown as a rich card in the library grid. Draggable to the week.
class ProgramCard extends ConsumerWidget {
  final DayProgram program;
  final VoidCallback onEdit;
  final VoidCallback onAddToWeek;

  const ProgramCard({
    super.key,
    required this.program,
    required this.onEdit,
    required this.onAddToWeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(programsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final sections = program.sectionCounts;

    Future<void> guarded(Future<void> Function() action, String okMsg) async {
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(okMsg)));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.drag_indicator,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      program.name.isEmpty ? 'Adsız Program' : program.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: _menu(context, notifier, messenger, guarded),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${program.exercises.length} egzersiz',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: sections.isEmpty
                    ? Text(
                        'Egzersiz yok',
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.onSurfaceVariant),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final entry in sections.entries)
                            _sectionChip(entry.key, entry.value),
                        ],
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: onAddToWeek,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Haftaya ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionChip(String section, int count) {
    final color = sectionColor(section);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$section · $count',
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    ProgramsNotifier notifier,
    ScaffoldMessengerState messenger,
    Future<void> Function(Future<void> Function(), String) guarded,
  ) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'duplicate':
            notifier.duplicate(program.id);
            messenger.showSnackBar(
                const SnackBar(content: Text('Program çoğaltıldı')));
            break;
          case 'archive':
            notifier.setArchived(program.id, !program.archived);
            break;
          case 'pdf':
            await guarded(() => PdfExporter.exportDayProgram(program),
                'PDF hazırlandı');
            break;
          case 'excel':
            await guarded(() => ExcelExporter.exportDayProgram(program),
                'Excel indirildi');
            break;
          case 'delete':
            final ok = await _confirmDelete(context, program.name);
            if (ok) {
              notifier.delete(program.id);
              messenger.showSnackBar(
                  const SnackBar(content: Text('Program silindi')));
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Düzenle'))),
        const PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Çoğalt / Yeniden oluştur'))),
        PopupMenuItem(
            value: 'archive',
            child: ListTile(
                leading: Icon(
                    program.archived ? Icons.unarchive : Icons.archive),
                title: Text(program.archived ? 'Arşivden çıkar' : 'Arşivle'))),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 'pdf',
            child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('PDF dışa aktar'))),
        const PopupMenuItem(
            value: 'excel',
            child: ListTile(
                leading: Icon(Icons.table_chart),
                title: Text('Excel dışa aktar'))),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 'delete',
            child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Sil'))),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('"$name" programı kalıcı olarak silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil')),
        ],
      ),
    );
    return result ?? false;
  }
}

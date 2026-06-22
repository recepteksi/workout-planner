import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/day_program.dart';
import '../providers/app_providers.dart';
import '../services/export/excel_exporter.dart';
import '../services/export/pdf_exporter.dart';

class ProgramCard extends ConsumerWidget {
  final DayProgram program;
  final VoidCallback onEdit;

  const ProgramCard({super.key, required this.program, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('dd.MM.yyyy');
    final notifier = ref.read(programsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> guarded(Future<void> Function() action, String okMsg) async {
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(okMsg)));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }

    return Card(
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(child: Text('${program.exercises.length}')),
        title: Text(program.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${program.exercises.length} egzersiz · ${df.format(program.updatedAt)}'),
        trailing: PopupMenuButton<String>(
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
                child: ListTile(
                    leading: Icon(Icons.edit), title: Text('Düzenle'))),
            const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Çoğalt / Yeniden oluştur'))),
            PopupMenuItem(
                value: 'archive',
                child: ListTile(
                    leading: Icon(program.archived
                        ? Icons.unarchive
                        : Icons.archive),
                    title: Text(
                        program.archived ? 'Arşivden çıkar' : 'Arşivle'))),
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
        ),
      ),
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

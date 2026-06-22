import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/day_program.dart';
import '../models/weekly_plan.dart';
import '../providers/app_providers.dart';
import '../services/export/excel_exporter.dart';
import '../services/export/pdf_exporter.dart';
import '../widgets/program_card.dart';
import 'day_program_editor_screen.dart';
import 'import_screen.dart';
import 'weekly_plan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider);
    final active = programs.where((p) => !p.archived).toList();
    final archived = programs.where((p) => p.archived).toList();
    final weekly = ref.watch(weeklyPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Programı'),
        actions: [
          IconButton(
            tooltip: 'İçe Aktar',
            icon: const Icon(Icons.file_download),
            onPressed: () => _push(const ImportScreen()),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Programlar', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Haftalık', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Arşiv', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _programList(active,
              emptyText: 'Henüz program yok.\nSağ alttan yeni program ekleyin.'),
          _weeklyList(weekly),
          _programList(archived,
              emptyText: 'Arşivlenmiş program yok.'),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  Widget? _fab() {
    switch (_tab.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => _push(const DayProgramEditorScreen()),
          icon: const Icon(Icons.add),
          label: const Text('Yeni Program'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _push(const WeeklyPlanEditorScreen()),
          icon: const Icon(Icons.add),
          label: const Text('Yeni Hafta'),
        );
      default:
        return null;
    }
  }

  Widget _programList(List<DayProgram> list, {required String emptyText}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final p = list[i];
        return ProgramCard(
          program: p,
          onEdit: () => _push(DayProgramEditorScreen(program: p)),
        );
      },
    );
  }

  Widget _weeklyList(List<WeeklyPlan> list) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Henüz haftalık plan yok.\nSağ alttan yeni hafta ekleyin.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final df = DateFormat('dd.MM.yyyy');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final plan = list[i];
        return Card(
          child: ListTile(
            onTap: () => _push(WeeklyPlanEditorScreen(plan: plan)),
            leading: CircleAvatar(child: Text('${plan.entries.length}')),
            title: Text(plan.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${plan.entries.length} gün · ${df.format(plan.updatedAt)}'),
            trailing: _weeklyMenu(plan),
          ),
        );
      },
    );
  }

  Widget _weeklyMenu(WeeklyPlan plan) {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(weeklyPlansProvider.notifier);

    Future<void> guarded(Future<void> Function() action, String okMsg) async {
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(okMsg)));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }

    return PopupMenuButton<String>(
      onSelected: (value) async {
        final programs = ref.read(programsProvider);
        switch (value) {
          case 'edit':
            _push(WeeklyPlanEditorScreen(plan: plan));
            break;
          case 'pdf':
            await guarded(
                () => PdfExporter.exportWeeklyPlan(plan, programs),
                'PDF hazırlandı');
            break;
          case 'excel':
            await guarded(
                () => ExcelExporter.exportWeeklyPlan(plan, programs),
                'Excel indirildi');
            break;
          case 'delete':
            notifier.delete(plan.id);
            messenger.showSnackBar(
                const SnackBar(content: Text('Haftalık plan silindi')));
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Düzenle'))),
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
}

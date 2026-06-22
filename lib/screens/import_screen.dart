import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_program.dart';
import '../models/exercise.dart';
import '../services/import/import_service.dart';
import 'day_program_editor_screen.dart';

/// Imports a program from text / CSV / Excel / PDF sources.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _textController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _openPreview(String name, List<Exercise> exercises) {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hiç egzersiz bulunamadı. İçeriği kontrol edin.')));
      return;
    }
    final draft = DayProgram(name: name, exercises: exercises);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayProgramEditorScreen(program: draft),
      ),
    );
  }

  void _parseText() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce bir metin yapıştırın')));
      return;
    }
    _openPreview('İçe Aktarılan Program', ImportService.fromText(text));
  }

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      final result = await ImportService.pickAndParse();
      if (result == null) return;
      final baseName = result.sourceName.replaceAll(RegExp(r'\.[^.]+$'), '');
      _openPreview(baseName.isEmpty ? 'İçe Aktarılan Program' : baseName,
          result.exercises);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dosya okunamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İçe Aktar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dosyadan içe aktar',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'CSV, Excel (.xlsx/.xls), PDF veya TXT dosyası seçin. '
                      'Çıkarılan egzersizler düzenleme için önizlemede açılır.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: const Text('Dosya Seç'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metinden içe aktar',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'Programı aşağıya yapıştırın. Her satır bir egzersiz olarak '
                      'okunur. Örnek: "Bench Press 4x10 60kg 90sn".'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    minLines: 6,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      hintText:
                          'Squat 5x5 100kg\nBench Press 4x8 60kg 90sn\nBarfiks 4x10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _parseText,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Ayrıştır ve Önizle'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

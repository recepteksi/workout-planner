import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import '../../models/day_program.dart';
import '../../models/weekly_plan.dart';

/// Generates programs as .xlsx and downloads them on the web.
class ExcelExporter {
  static const _headers = [
    'Egzersiz',
    'Set',
    'Tekrar',
    'Ağırlık',
    'Dinlenme',
    'Not',
  ];

  static Future<void> exportDayProgram(DayProgram program) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    final sheet = excel[_sheetName(program.name)];
    _fillSheet(sheet, program);
    excel.delete(defaultSheet);
    await _save(excel, program.name);
  }

  static Future<void> exportWeeklyPlan(
    WeeklyPlan plan,
    List<DayProgram> programs,
  ) async {
    final byId = {for (final p in programs) p.id: p};
    final entries = [...plan.entries]
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet()!;
    for (final e in entries) {
      final prog = byId[e.dayProgramId];
      if (prog == null) continue;
      final sheet = excel[_sheetName('${e.weekdayName}-${prog.name}')];
      _fillSheet(sheet, prog);
    }
    // Keep at least one sheet: only delete the default if another sheet exists.
    if (excel.sheets.length > 1) {
      excel.delete(defaultSheet);
    }
    await _save(excel, plan.name);
  }

  static void _fillSheet(Sheet sheet, DayProgram program) {
    sheet.appendRow([TextCellValue(program.name)]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(_headers.map((h) => TextCellValue(h)).toList());
    for (final ex in program.exercises) {
      sheet.appendRow([
        TextCellValue(ex.name),
        TextCellValue(ex.sets),
        TextCellValue(ex.reps),
        TextCellValue(ex.weight ?? ''),
        TextCellValue(ex.rest ?? ''),
        TextCellValue(ex.note ?? ''),
      ]);
    }
  }

  static Future<void> _save(Excel excel, String name) async {
    final encoded = excel.encode();
    if (encoded == null) return;
    await FileSaver.instance.saveFile(
      name: _safeName(name),
      bytes: Uint8List.fromList(encoded),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static String _safeName(String name) {
    final cleaned =
        name.trim().replaceAll(RegExp(r'[^\w\sçğıöşüÇĞİÖŞÜ-]'), '').trim();
    return cleaned.isEmpty ? 'program' : cleaned;
  }

  /// Excel sheet names are limited to 31 chars and reject some characters.
  static String _sheetName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\[\]\*/\\?:]'), ' ').trim();
    if (cleaned.isEmpty) cleaned = 'Program';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }
}

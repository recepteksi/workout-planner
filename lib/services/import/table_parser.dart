import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../models/exercise.dart';

/// Parses CSV and Excel (.xlsx) tables into exercises.
///
/// If a header row is present, columns are mapped by name (exercise/sets/reps/
/// weight/rest/note). Without a header, column order is: name, sets, reps,
/// weight, rest, note.
class TableParser {
  static List<Exercise> fromCsv(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    final rows = csv.decode(normalized);
    return _fromRows(rows);
  }

  static List<Exercise> fromExcelBytes(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows
        .map((r) => r.map<dynamic>(_cellValue).toList())
        .toList();
    return _fromRows(rows);
  }

  static dynamic _cellValue(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value;
    if (v is TextCellValue) return v.value.toString();
    return v.toString();
  }

  static List<Exercise> _fromRows(List<List<dynamic>> rows) {
    // Drop empty rows.
    final data = rows
        .where((r) => r.any((c) => c != null && '$c'.trim().isNotEmpty))
        .toList();
    if (data.isEmpty) return [];

    // Detect a header row.
    final first = data.first.map((c) => '${c ?? ''}'.toLowerCase().trim()).toList();
    final hasHeader = first.any((c) =>
        c.contains('egzersiz') ||
        c.contains('exercise') ||
        c.contains('hareket') ||
        c == 'ad' ||
        c == 'name');

    var idx = {'name': 0, 'sets': 1, 'reps': 2, 'weight': 3, 'rest': 4, 'note': 5};
    var startRow = 0;
    if (hasHeader) {
      idx = _mapHeader(first);
      startRow = 1;
    }

    final result = <Exercise>[];
    for (var i = startRow; i < data.length; i++) {
      final row = data[i];
      String cell(String key) {
        final col = idx[key];
        if (col == null || col < 0 || col >= row.length) return '';
        return '${row[col] ?? ''}'.trim();
      }

      final name = cell('name');
      if (name.isEmpty) continue;
      result.add(Exercise(
        name: name,
        sets: _toInt(cell('sets')) ?? 3,
        reps: _toInt(cell('reps')) ?? 10,
        weight: _toDouble(cell('weight')),
        restSeconds: _toInt(cell('rest')),
        note: cell('note').isEmpty ? null : cell('note'),
      ));
    }
    return result;
  }

  static Map<String, int> _mapHeader(List<String> header) {
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final h = header[i];
      if (map['name'] == null &&
          (h.contains('egzersiz') ||
              h.contains('exercise') ||
              h.contains('hareket') ||
              h == 'ad' ||
              h == 'name')) {
        map['name'] = i;
      } else if (map['sets'] == null && (h.contains('set'))) {
        map['sets'] = i;
      } else if (map['reps'] == null &&
          (h.contains('tekrar') || h.contains('rep'))) {
        map['reps'] = i;
      } else if (map['weight'] == null &&
          (h.contains('ağırlık') ||
              h.contains('agirlik') ||
              h.contains('weight') ||
              h.contains('kg'))) {
        map['weight'] = i;
      } else if (map['rest'] == null &&
          (h.contains('dinlenme') ||
              h.contains('rest') ||
              h.contains('mola'))) {
        map['rest'] = i;
      } else if (map['note'] == null &&
          (h.contains('not') || h.contains('note') || h.contains('açıklama'))) {
        map['note'] = i;
      }
    }
    map['name'] ??= 0;
    return map;
  }

  static int? _toInt(String s) {
    if (s.isEmpty) return null;
    final m = RegExp(r'\d+').firstMatch(s);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  static double? _toDouble(String s) {
    if (s.isEmpty) return null;
    final m = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(s.replaceAll(',', '.'));
    return m == null ? null : double.tryParse(m.group(0)!);
  }
}

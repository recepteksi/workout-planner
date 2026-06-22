import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../models/exercise.dart';
import 'pdf_parser.dart';
import 'table_parser.dart';
import 'text_parser.dart';

class ImportResult {
  final String sourceName;
  final List<Exercise> exercises;
  ImportResult(this.sourceName, this.exercises);
}

/// Produces an exercise list from various sources (text / CSV / Excel / PDF).
class ImportService {
  static const allowedExtensions = ['csv', 'xlsx', 'xls', 'pdf', 'txt'];

  static List<Exercise> fromText(String text) => TextParser.parse(text);

  /// Prompts for a file and runs the matching parser based on its type.
  /// Returns null if the user cancels.
  static Future<ImportResult?> pickAndParse() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true, // needed to get bytes on the web
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final ext = (file.extension ?? '').toLowerCase();
    final exercises = parseBytes(bytes, ext);
    return ImportResult(file.name, exercises);
  }

  static List<Exercise> parseBytes(Uint8List bytes, String ext) {
    switch (ext) {
      case 'pdf':
        return PdfParser.fromBytes(bytes);
      case 'xlsx':
      case 'xls':
        return TableParser.fromExcelBytes(bytes);
      case 'csv':
        return TableParser.fromCsv(utf8.decode(bytes, allowMalformed: true));
      case 'txt':
      default:
        return TextParser.parse(utf8.decode(bytes, allowMalformed: true));
    }
  }
}

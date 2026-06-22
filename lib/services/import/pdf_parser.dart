import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../models/exercise.dart';
import 'text_parser.dart';

/// Extracts text from a PDF and parses it into exercises via [TextParser].
class PdfParser {
  static List<Exercise> fromBytes(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final text = PdfTextExtractor(document).extractText();
      return TextParser.parse(text);
    } finally {
      document.dispose();
    }
  }

  /// Returns the raw extracted text (for preview/editing).
  static String extractText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }
}

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// Verifies that the bundled Unicode font renders Turkish glyphs without
/// throwing or dropping characters — the default Helvetica font cannot, which
/// crashed PDF export.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF with Turkish glyphs generates without crashing', () async {
    final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.Page(
        build: (_) => pw.Text(
          'İtiş · Çekiş · ısınma · esneme · ağırlık · şınav',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    final bytes = await doc.save();
    expect(bytes.lengthInBytes, greaterThan(0));
  });
}

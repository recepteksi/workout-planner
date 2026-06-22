import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/day_program.dart';
import '../../models/weekly_plan.dart';

/// Generates programs as PDF and downloads/prints them on the web.
class PdfExporter {
  static final _df = DateFormat('dd.MM.yyyy');

  /// Download a single daily program as PDF.
  static Future<void> exportDayProgram(DayProgram program) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [_dayProgramSection(program)],
      ),
    );
    await _share(doc, _safeName(program.name));
  }

  /// Download a weekly plan as PDF, with the program for each day.
  static Future<void> exportWeeklyPlan(
    WeeklyPlan plan,
    List<DayProgram> programs,
  ) async {
    final byId = {for (final p in programs) p.id: p};
    final entries = [...plan.entries]
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Header(level: 0, text: plan.name),
            pw.SizedBox(height: 8),
          ];
          for (final e in entries) {
            final prog = byId[e.dayProgramId];
            widgets.add(pw.Text(e.weekdayName,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)));
            if (prog == null) {
              widgets.add(pw.Text('— program bulunamadı —'));
            } else {
              widgets.add(_dayProgramSection(prog, showTitle: true));
            }
            widgets.add(pw.SizedBox(height: 14));
          }
          return widgets;
        },
      ),
    );
    await _share(doc, _safeName(plan.name));
  }

  static pw.Widget _dayProgramSection(DayProgram program,
      {bool showTitle = true}) {
    final headers = ['#', 'Egzersiz', 'Set', 'Tekrar', 'Ağırlık', 'Dinlenme', 'Not'];
    final rows = <List<String>>[];
    for (var i = 0; i < program.exercises.length; i++) {
      final ex = program.exercises[i];
      rows.add([
        '${i + 1}',
        ex.name,
        ex.sets.isEmpty ? '-' : ex.sets,
        ex.reps.isEmpty ? '-' : ex.reps,
        (ex.weight ?? '').isEmpty ? '-' : ex.weight!,
        (ex.rest ?? '').isEmpty ? '-' : ex.rest!,
        ex.note ?? '',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (showTitle)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(program.name,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
        pw.Text('Oluşturulma: ${_df.format(program.createdAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 6),
        if (rows.isEmpty)
          pw.Text('Egzersiz yok.')
        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(30),
              3: const pw.FixedColumnWidth(40),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(55),
              6: const pw.FlexColumnWidth(2),
            },
          ),
      ],
    );
  }

  static Future<void> _share(pw.Document doc, String name) async {
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }

  static String _safeName(String name) {
    final cleaned =
        name.trim().replaceAll(RegExp(r'[^\w\sçğıöşüÇĞİÖŞÜ-]'), '').trim();
    return cleaned.isEmpty ? 'program' : cleaned;
  }
}

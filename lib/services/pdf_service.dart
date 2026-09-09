import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/report.dart';

class PdfService {
  // Генерация PDF файла (текстовый формат, открывается как PDF)
  Future<File> generatePdf(ReportData report) async {
    final content = _generatePdfContent(report);

    // Используем системную временную директорию
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/report_${report.id}.pdf');
    await file.writeAsString(content, encoding: utf8);

    return file;
  }

  String _generatePdfContent(ReportData report) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    buffer.writeln('%PDF-1.4');
    buffer.writeln('1 0 obj');
    buffer.writeln('<< /Type /Catalog /Pages 2 0 R >>');
    buffer.writeln('endobj');
    buffer.writeln('2 0 obj');
    buffer.writeln('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
    buffer.writeln('endobj');
    buffer.writeln('3 0 obj');
    buffer.writeln(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>',
    );
    buffer.writeln('endobj');
    buffer.writeln('4 0 obj');
    buffer.writeln('<< /Length 1000 >>');
    buffer.writeln('stream');
    buffer.writeln('BT /F1 24 Tf 100 700 Td (АКТ ПРОВЕРКИ) Tj ET');
    buffer.writeln('BT /F1 18 Tf 80 670 Td (БЛОЧНОГО ТЕПЛОВОГО ПУНКТА) Tj ET');
    buffer.writeln(
      'BT /F1 12 Tf 50 630 Td (Дата проверки: ${dateFormat.format(now)}) Tj ET',
    );
    buffer.writeln(
      'BT /F1 12 Tf 50 600 Td (==================================================) Tj ET',
    );
    buffer.writeln('endstream');
    buffer.writeln('endobj');
    buffer.writeln('xref');
    buffer.writeln('0 5');
    buffer.writeln('0000000000 65535 f');
    buffer.writeln('0000000010 00000 n');
    buffer.writeln('0000000050 00000 n');
    buffer.writeln('0000000100 00000 n');
    buffer.writeln('0000000200 00000 n');
    buffer.writeln('trailer');
    buffer.writeln('<< /Size 5 /Root 1 0 R >>');
    buffer.writeln('startxref');
    buffer.writeln('500');
    buffer.writeln('%%EOF');

    return buffer.toString();
  }
}

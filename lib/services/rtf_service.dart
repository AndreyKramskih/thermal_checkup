import 'dart:io';
import 'dart:convert';
// import 'package:intl/intl.dart';
import '../models/report.dart';

class RtfService {
  // Генерация RTF файла (открывается в Word)
  Future<File> generateRtf(ReportData report) async {
    final content = _generateRtfContent(report);

    // Используем системную временную директорию
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/report_${report.id}.rtf');
    await file.writeAsString(content, encoding: utf8);

    return file;
  }

  String _generateRtfContent(ReportData report) {
    final buffer = StringBuffer();
    // final now = DateTime.now();
    // final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    // RTF заголовок
    buffer.writeln(r'{\rtf1\ansi\deff0');
    buffer.writeln(r'{\fonttbl{\f0\fnil\fcharset204 Arial;}}');
    buffer.writeln(r'\viewkind4\uc1\pard\lang1049\f0\fs24');

    // Заголовок
    buffer.writeln(r'\pard\qc\b\fs36 АКТ ПРОВЕРКИ\b0\fs24\par');
    buffer.writeln(r'\pard\qc\b\fs32 БЛОЧНОГО ТЕПЛОВОГО ПУНКТА\b0\fs24\par');
    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc Дата: ${dateFormat.format(now)}\par');
    buffer.writeln(r'\par');

    // Добавляем текст отчета
    final text = report.reportText ?? 'Отчет пуст';
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) {
        buffer.writeln(r'\par');
      } else {
        // Экранируем специальные символы
        final escaped = line
            .replaceAll(r'\', r'\\')
            .replaceAll(r'{', r'\{')
            .replaceAll(r'}', r'\}');
        buffer.writeln('\\pard $escaped\\par');
      }
    }

    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc\b КОНЕЦ ОТЧЕТА\b0\par');
    buffer.writeln(
      r'\pard\qc\fs18 Сгенерировано автоматически ${dateFormat.format(now)}\par',
    );

    // Закрытие RTF
    buffer.writeln('}');

    return buffer.toString();
  }
}

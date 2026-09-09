import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/report.dart';

class DocxService {
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
    final now = DateTime.now();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');
    final fullFormat = DateFormat('dd.MM.yyyy HH:mm');

    // RTF заголовок
    buffer.writeln(r'{\rtf1\ansi\deff0');
    buffer.writeln(r'{\fonttbl{\f0\fnil\fcharset204 Arial;}}');
    buffer.writeln(r'\viewkind4\uc1\pard\lang1049\f0\fs24');

    // Заголовок
    buffer.writeln(r'\pard\qc\b\fs36 АКТ ПРОВЕРКИ\b0\fs24\par');
    buffer.writeln(r'\pard\qc\b\fs32 БЛОЧНОГО ТЕПЛОВОГО ПУНКТА\b0\fs24\par');
    buffer.writeln(r'\par');
    buffer.writeln('\\pard\\qc Дата проверки: ${dateFormat.format(now)}\\par');
    buffer.writeln('\\pard\\qc Время: ${timeFormat.format(now)}\\par');
    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc \b1. ПРОВЕРКА ПОСЛЕ МОНТАЖА\b0\par');
    buffer.writeln(r'\par');

    // Чеклист
    final checklist =
        report.data['checklistItems']
            as Map<String, List<Map<String, dynamic>>>?;
    if (checklist != null) {
      int totalChecked = 0;
      int totalItems = 0;

      for (var entry in checklist.entries) {
        buffer.writeln('\\pard\\b ${entry.key}\\b0\\par');

        for (var item in entry.value) {
          final isChecked = item['isChecked'] ?? false;
          final title = item['title'] ?? '';
          final comment = item['comment'] ?? '';
          totalChecked += isChecked ? 1 : 0;
          totalItems += 1;

          final status = isChecked ? '[+]' : '[-]';
          buffer.writeln('\\pard\\fs20 $status $title\\par');

          if (comment.isNotEmpty) {
            buffer.writeln('\\pard\\fs18\\i Комментарий: $comment\\i0\\par');
          }
        }
        buffer.writeln(r'\par');
      }

      buffer.writeln(
        '\\pard\\b Итого: $totalChecked из $totalItems проверено\\b0\\par',
      );
    }

    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc \b2. ПРОВЕРКА ЭЛЕКТРОМОНТАЖА\b0\par');
    buffer.writeln(r'\par');

    // Электромонтаж
    final electrical = report.data['electricalData'] as Map<String, dynamic>?;
    if (electrical != null) {
      final sensors = electrical['sensors'] ?? 'Не проверено';
      final relays = electrical['relays'] ?? 'Не проверено';
      final pumps = electrical['pumps'] ?? 'Не проверено';
      final actuators = electrical['actuators'] ?? 'Не проверено';
      final cableMarking = electrical['cableMarking'] ?? 'Не проверено';
      final cableTypes = electrical['cableTypes'] ?? 'Не проверено';

      buffer.writeln(
        '\\pard • Соответствие подключения датчиков: $sensors\\par',
      );
      buffer.writeln('\\pard • Соответствие подключения реле: $relays\\par');
      buffer.writeln('\\pard • Соответствие подключения насосов: $pumps\\par');
      buffer.writeln(
        '\\pard • Соответствие подключения приводов: $actuators\\par',
      );
      buffer.writeln('\\pard • Маркировка кабелей: $cableMarking\\par');
      buffer.writeln('\\pard • Соответствие типов кабелей: $cableTypes\\par');
    }

    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc \b3. РЕЗУЛЬТАТЫ ПНР\b0\par');
    buffer.writeln(r'\par');

    // ПНР
    final commissioning =
        report.data['commissioningData'] as Map<String, dynamic>?;
    if (commissioning != null) {
      final controllerProgram =
          commissioning['controllerProgram'] ?? 'Не проверено';
      final panelProgram = commissioning['panelProgram'] ?? 'Не проверено';
      final cabinetAssembly =
          commissioning['cabinetAssembly'] ?? 'Не проверено';
      final electricalScheme =
          commissioning['electricalScheme'] ?? 'Не проверено';
      final componentsQuality =
          commissioning['componentsQuality'] ?? 'Не проверено';
      final regulationQuality =
          commissioning['regulationQuality'] ?? 'Не проверено';

      buffer.writeln(
        '\\pard • Работоспособность программы в контроллере: $controllerProgram\\par',
      );
      buffer.writeln(
        '\\pard • Работоспособность программы в панели: $panelProgram\\par',
      );
      buffer.writeln(
        '\\pard • Правильность сборки шкафа: $cabinetAssembly\\par',
      );
      buffer.writeln(
        '\\pard • Правильность электросхемы: $electricalScheme\\par',
      );
      buffer.writeln(
        '\\pard • Отсутствие брака в компонентах: $componentsQuality\\par',
      );
      buffer.writeln(
        '\\pard • Качество регулирования: $regulationQuality\\par',
      );
    }

    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc \b4. ФОТОМАТЕРИАЛЫ\b0\par');
    buffer.writeln(r'\par');

    final photos = report.data['photoPaths'] as List<String>?;
    if (photos == null || photos.isEmpty) {
      buffer.writeln(r'\pard Фотографии не прикреплены\par');
    } else {
      buffer.writeln('\\pard Добавлено фотографий: ${photos.length}\\par');
      for (var i = 0; i < photos.length; i++) {
        final fileName = photos[i].split('/').last;
        buffer.writeln('\\pard ${i + 1}. $fileName\\par');
      }
    }

    buffer.writeln(r'\par');
    buffer.writeln(r'\pard\qc\b КОНЕЦ ОТЧЕТА\b0\par');
    buffer.writeln(
      '\\pard\\qc\\fs18 Отчет сгенерирован автоматически ${fullFormat.format(now)}\\par',
    );

    // Закрытие RTF
    buffer.writeln('}');

    return buffer.toString();
  }
}

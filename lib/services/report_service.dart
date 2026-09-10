import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../models/check_item.dart';

class ReportService {
  // ========== ГЕНЕРАЦИЯ ТЕКСТА ==========
  Future<ReportData> generateReport({
    required Map<String, List> checklistItems,
    required List<String> photoPaths,
    required List<String> photoDescriptions,
    required Map<String, dynamic> electricalData,
    required Map<String, dynamic> commissioningData,
  }) async {
    final id = 'report_${DateTime.now().millisecondsSinceEpoch}';
    final data = {
      'generatedAt': DateTime.now().toIso8601String(),
      'checklistItems': _serializeChecklist(checklistItems),
      'photoPaths': photoPaths,
      'photoDescriptions': photoDescriptions,
      'electricalData': electricalData,
      'commissioningData': commissioningData,
    };

    final reportText = _generateReportText(data);

    return ReportData(
      id: id,
      generatedAt: DateTime.now(),
      data: data,
      pdfPath: '',
      reportText: reportText,
    );
  }

  Map<String, List<Map<String, dynamic>>> _serializeChecklist(
    Map<String, List> checklistItems,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (var entry in checklistItems.entries) {
      final items = <Map<String, dynamic>>[];
      for (var item in entry.value) {
        if (item is CheckItem) {
          items.add({
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'isChecked': item.isChecked,
            'comment': item.comment,
            'orderIndex': item.orderIndex,
          });
        } else if (item is Map) {
          items.add(item.cast<String, dynamic>());
        }
      }
      result[entry.key] = items;
    }
    return result;
  }

  String _generateReportText(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');
    final fullFormat = DateFormat('dd.MM.yyyy HH:mm');

    buffer.writeln('=' * 50);
    buffer.writeln('АКТ ПРОВЕРКИ БЛОЧНОГО ТЕПЛОВОГО ПУНКТА');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Дата проверки: ${dateFormat.format(now)}');
    buffer.writeln('Время: ${timeFormat.format(now)}');
    buffer.writeln();
    buffer.writeln('-' * 50);

    // 1. Проверка после монтажа
    buffer.writeln();
    buffer.writeln('1. ПРОВЕРКА ПОСЛЕ МОНТАЖА');
    buffer.writeln('-' * 40);

    final checklist =
        data['checklistItems'] as Map<String, List<Map<String, dynamic>>>?;
    if (checklist != null && checklist.isNotEmpty) {
      int totalChecked = 0;
      int totalItems = 0;

      for (var entry in checklist.entries) {
        buffer.writeln();
        buffer.writeln('  >> ${entry.key}:');
        for (var item in entry.value) {
          final isChecked = item['isChecked'] ?? false;
          final title = item['title'] ?? '';
          final comment = item['comment'] ?? '';
          totalChecked += isChecked ? 1 : 0;
          totalItems += 1;
          buffer.writeln('    ${isChecked ? '[+]' : '[-]'} $title');
          if (comment.isNotEmpty) {
            buffer.writeln('      Комментарий: $comment');
          }
        }
      }

      buffer.writeln();
      buffer.writeln('Итого: $totalChecked из $totalItems проверено');
    } else {
      buffer.writeln('  Нет данных по проверке монтажа');
    }

    // 2. Проверка электромонтажа
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('2. ПРОВЕРКА ЭЛЕКТРОМОНТАЖА');
    buffer.writeln('-' * 40);

    final electrical = data['electricalData'] as Map<String, dynamic>?;
    final electricalComments =
        electrical?['comments'] as Map<String, dynamic>? ?? {};

    if (electrical != null) {
      final electricalItems = [
        {
          'key': 'sensors',
          'commentKey': 'Датчики подключены согласно схеме',
          'label': 'Соответствие подключения датчиков',
        },
        {
          'key': 'relays',
          'commentKey': 'Реле подключены согласно схеме',
          'label': 'Соответствие подключения реле',
        },
        {
          'key': 'pumps',
          'commentKey': 'Насосы подключены согласно схеме',
          'label': 'Соответствие подключения насосов',
        },
        {
          'key': 'actuators',
          'commentKey': 'Привода подключены согласно схеме',
          'label': 'Соответствие подключения приводов',
        },
        {
          'key': 'cableMarking',
          'commentKey': 'Кабеля промаркированы согласно схеме',
          'label': 'Маркировка кабелей',
        },
        {
          'key': 'cableTypes',
          'commentKey': 'Тип кабелей соответствует схеме',
          'label': 'Соответствие типов кабелей',
        },
      ];

      for (var item in electricalItems) {
        buffer.writeln(
          '  • ${item['label']}: ${electrical[item['key']] ?? 'Не проверено'}',
        );
        final comment =
            electricalComments[item['commentKey']]?.toString() ?? '';
        if (comment.isNotEmpty) {
          buffer.writeln('      Комментарий: $comment');
        }
      }
    }

    // 3. Результаты ПНР
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('3. РЕЗУЛЬТАТЫ ПНР');
    buffer.writeln('-' * 40);

    final commissioning = data['commissioningData'] as Map<String, dynamic>?;
    final commissioningComments =
        commissioning?['comments'] as Map<String, dynamic>? ?? {};

    if (commissioning != null) {
      final commissioningItems = [
        {
          'key': 'controllerProgram',
          'commentKey': 'Работоспособность программы в контроллере',
          'label': 'Работоспособность программы в контроллере',
        },
        {
          'key': 'panelProgram',
          'commentKey': 'Работоспособность программы в панели',
          'label': 'Работоспособность программы в панели',
        },
        {
          'key': 'cabinetAssembly',
          'commentKey': 'Правильность сборки шкафа согласно схемы',
          'label': 'Правильность сборки шкафа',
        },
        {
          'key': 'electricalScheme',
          'commentKey': 'Правильность электросхемы',
          'label': 'Правильность электросхемы',
        },
        {
          'key': 'componentsQuality',
          'commentKey': 'Отсутствие брака в компонентах',
          'label': 'Отсутствие брака в компонентах',
        },
        {
          'key': 'regulationQuality',
          'commentKey': 'Качество регулирования',
          'label': 'Качество регулирования',
        },
      ];

      for (var item in commissioningItems) {
        buffer.writeln(
          '  • ${item['label']}: ${commissioning[item['key']] ?? 'Не проверено'}',
        );
        final comment =
            commissioningComments[item['commentKey']]?.toString() ?? '';
        if (comment.isNotEmpty) {
          buffer.writeln('      Комментарий: $comment');
        }
      }
    }

    // 4. Фотоматериалы
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('4. ФОТОМАТЕРИАЛЫ');
    buffer.writeln('-' * 40);

    final photoPaths = data['photoPaths'] as List<String>?;
    final photoDescriptions = data['photoDescriptions'] as List<String>? ?? [];

    if (photoPaths == null || photoPaths.isEmpty) {
      buffer.writeln('  Фотографии не прикреплены');
    } else {
      buffer.writeln('  Добавлено фотографий: ${photoPaths.length}');
      for (var i = 0; i < photoPaths.length; i++) {
        final description =
            (photoDescriptions.isNotEmpty && i < photoDescriptions.length)
            ? photoDescriptions[i]
            : photoPaths[i].split('/').last;
        buffer.writeln('    ${i + 1}. $description');
      }
    }

    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('КОНЕЦ ОТЧЕТА');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Отчет сгенерирован автоматически');
    buffer.writeln('Время генерации: ${fullFormat.format(now)}');

    return buffer.toString();
  }

  // ========== ГЕНЕРАЦИЯ PDF ==========
  pw.Font? _font;

  Future<void> _loadFont() async {
    if (_font != null) return;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      _font = pw.Font.ttf(fontData);
      print('✅ Шрифт Roboto загружен');
    } catch (e) {
      print('⚠️ Ошибка загрузки шрифта: $e');
      _font = pw.Font.helvetica();
    }
  }

  // ========== СОХРАНЕНИЕ С FALLBACK ==========
  Future<File> generateAndSavePdf({
    required String projectName,
    required DateTime reportTime,
    required String reportText,
  }) async {
    print('📄 Генерация PDF отчета...');

    await _loadFont();
    final font = _font ?? pw.Font.helvetica();

    final pdf = pw.Document();

    String cleanText = reportText;
    cleanText = cleanText.replaceAll('✅', '[+]');
    cleanText = cleanText.replaceAll('❌', '[-]');
    cleanText = cleanText.replaceAll('📅', 'Дата:');
    cleanText = cleanText.replaceAll('⏰', 'Время:');
    cleanText = cleanText.replaceAll('📂', '>>');
    cleanText = cleanText.replaceAll('💬', 'Комм:');
    cleanText = cleanText.replaceAll('📊', 'Итого:');
    cleanText = cleanText.replaceAll('⚡', '•');
    cleanText = cleanText.replaceAll('🔧', '•');
    cleanText = cleanText.replaceAll('📷', 'Фото:');

    final lines = cleanText.split('\n');
    final pages = _splitTextIntoPages(lines);

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageLines = pages[pageIndex];
      final isFirstPage = pageIndex == 0;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPage(
              lines: pageLines,
              projectName: projectName,
              reportTime: reportTime,
              font: font,
              isFirstPage: isFirstPage,
              pageNumber: pageIndex + 1,
              totalPages: pages.length,
            );
          },
        ),
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(reportTime);

    // Очищаем имя проекта от недопустимых символов
    String safeProjectName = projectName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    if (safeProjectName.isEmpty) safeProjectName = 'ИТП';

    final filename = 'Отчет_${safeProjectName}_$dateStr.pdf';

    // ✅ FALLBACK: список путей по приоритету
    final List<String> possibleDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Android/data/com.example.thermal_checkup/files',
      Directory.systemTemp.path,
    ];

    final Uint8List pdfBytes = await pdf.save();
    File? savedFile;
    String? lastError;
    final List<String> triedPaths = [];

    for (final dirPath in possibleDirs) {
      try {
        final dir = Directory(dirPath);
        triedPaths.add(dirPath);

        if (!await dir.exists()) {
          try {
            await dir.create(recursive: true);
          } catch (e) {
            lastError = 'Не могу создать папку $dirPath: $e';
            print('⚠️ $lastError');
            continue;
          }
        }

        final filePath = '$dirPath/$filename';
        final file = File(filePath);

        // Записываем файл
        await file.writeAsBytes(pdfBytes);

        // Проверяем что файл реально записался
        if (await file.exists()) {
          final size = await file.length();
          if (size > 0) {
            savedFile = file;
            print('✅ PDF сохранен: $filePath (${(size / 1024).round()} KB)');
            break;
          } else {
            lastError = 'Файл создан, но пустой: $filePath';
            print('⚠️ $lastError');
          }
        } else {
          lastError = 'Файл не создан: $filePath';
          print('⚠️ $lastError');
        }
      } catch (e) {
        lastError = 'Ошибка записи в $dirPath: $e';
        print('⚠️ $lastError');
        continue;
      }
    }

    if (savedFile == null) {
      throw Exception(
        'Не удалось сохранить PDF.\n'
        'Проверенные пути: ${triedPaths.join(", ")}\n'
        'Последняя ошибка: $lastError',
      );
    }

    print('✅ PDF итог: ${savedFile.path} (${pages.length} страниц)');
    return savedFile;
  }

  List<List<String>> _splitTextIntoPages(List<String> allLines) {
    final pages = <List<String>>[];
    List<String> currentPage = [];
    double currentHeight = 0;
    const double maxHeight = 750;

    currentHeight = 100;

    for (final line in allLines) {
      if (line.trim().isEmpty && currentPage.isEmpty) {
        continue;
      }

      double lineHeight = 18;
      if (line.contains('=') || line.contains('-')) {
        lineHeight = 12;
      } else if (line.contains('АКТ') ||
          line.contains('ПРОВЕРКА') ||
          line.contains('РЕЗУЛЬТАТЫ') ||
          line.contains('КОНЕЦ') ||
          line.contains('1.') ||
          line.contains('2.') ||
          line.contains('3.') ||
          line.contains('4.') ||
          line.contains('Итого:')) {
        lineHeight = 22;
      }

      if (line.trim().isEmpty) {
        lineHeight = 8;
      }

      if (currentHeight + lineHeight > maxHeight) {
        if (currentPage.isNotEmpty) {
          pages.add(List.from(currentPage));
          currentPage = [];
          currentHeight = 20;
        }
      }

      currentPage.add(line);
      currentHeight += lineHeight;
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    if (pages.isEmpty) {
      pages.add([]);
    }

    return pages;
  }

  pw.Widget _buildPage({
    required List<String> lines,
    required String projectName,
    required DateTime reportTime,
    required pw.Font font,
    required bool isFirstPage,
    required int pageNumber,
    required int totalPages,
  }) {
    final children = <pw.Widget>[];

    if (isFirstPage) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColors.blue,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'АКТ ПРОВЕРКИ',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'БЛОЧНОГО ТЕПЛОВОГО ПУНКТА',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                projectName,
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Дата формирования: ${DateFormat('dd.MM.yyyy HH:mm').format(reportTime)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
            ],
          ),
        ),
      );
      children.add(pw.SizedBox(height: 8));
    } else {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          color: PdfColors.blue,
          child: pw.Text(
            'Продолжение отчета',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: font,
            ),
          ),
        ),
      );
      children.add(pw.SizedBox(height: 8));
    }

    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(pw.SizedBox(height: 6));
        continue;
      }

      bool isBold =
          line.contains('АКТ') ||
          line.contains('БЛОЧНОГО') ||
          line.contains('ПРОВЕРКА') ||
          line.contains('РЕЗУЛЬТАТЫ') ||
          line.contains('ИТОГО') ||
          line.contains('КОНЕЦ') ||
          line.contains('1.') ||
          line.contains('2.') ||
          line.contains('3.') ||
          line.contains('4.');

      bool isHeader = line.contains('=') || line.contains('-');
      String cleanLine = line.trim();

      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: pw.Text(
            cleanLine,
            style: pw.TextStyle(
              fontSize: isHeader ? 10 : (isBold ? 14 : 12),
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: font,
              color: PdfColors.black,
            ),
          ),
        ),
      );
    }

    children.add(pw.SizedBox(height: 16));
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Страница $pageNumber из $totalPages',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, font: font),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }
}

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
        buffer.writeln('  ${entry.key}:');
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
    buffer.writeln('-' * 60);
    buffer.writeln('2. ПРОВЕРКА ЭЛЕКТРОМОНТАЖА');
    buffer.writeln('-' * 40);

    final electrical = data['electricalData'] as Map<String, dynamic>?;
    final electricalComments =
        electrical?['comments'] as Map<String, String>? ?? {};

    if (electrical != null) {
      buffer.writeln(
        '  • Соответствие подключения датчиков: ${electrical['sensors'] ?? 'Не проверено'}',
      );
      if (electricalComments['Датчики подключены согласно схеме']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Датчики подключены согласно схеме']}',
        );
      }

      buffer.writeln(
        '  • Соответствие подключения реле: ${electrical['relays'] ?? 'Не проверено'}',
      );
      if (electricalComments['Реле подключены согласно схеме']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Реле подключены согласно схеме']}',
        );
      }

      buffer.writeln(
        '  • Соответствие подключения насосов: ${electrical['pumps'] ?? 'Не проверено'}',
      );
      if (electricalComments['Насосы подключены согласно схеме']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Насосы подключены согласно схеме']}',
        );
      }

      buffer.writeln(
        '  • Соответствие подключения приводов: ${electrical['actuators'] ?? 'Не проверено'}',
      );
      if (electricalComments['Привода подключены согласно схеме']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Привода подключены согласно схеме']}',
        );
      }

      buffer.writeln(
        '  • Маркировка кабелей: ${electrical['cableMarking'] ?? 'Не проверено'}',
      );
      if (electricalComments['Кабеля промаркированы согласно схеме']
              ?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Кабеля промаркированы согласно схеме']}',
        );
      }

      buffer.writeln(
        '  • Соответствие типов кабелей: ${electrical['cableTypes'] ?? 'Не проверено'}',
      );
      if (electricalComments['Тип кабелей соответствует схеме']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${electricalComments['Тип кабелей соответствует схеме']}',
        );
      }
    }

    // 3. Результаты ПНР
    buffer.writeln();
    buffer.writeln('-' * 60);
    buffer.writeln('3. РЕЗУЛЬТАТЫ ПНР');
    buffer.writeln('-' * 40);

    final commissioning = data['commissioningData'] as Map<String, dynamic>?;
    final commissioningComments =
        commissioning?['comments'] as Map<String, String>? ?? {};

    if (commissioning != null) {
      buffer.writeln(
        '  • Работоспособность программы в контроллере: ${commissioning['controllerProgram'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Работоспособность программы в контроллере']
              ?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Работоспособность программы в контроллере']}',
        );
      }

      buffer.writeln(
        '  • Работоспособность программы в панели: ${commissioning['panelProgram'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Работоспособность программы в панели']
              ?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Работоспособность программы в панели']}',
        );
      }

      buffer.writeln(
        '  • Правильность сборки шкафа: ${commissioning['cabinetAssembly'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Правильность сборки шкафа согласно схемы']
              ?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Правильность сборки шкафа согласно схемы']}',
        );
      }

      buffer.writeln(
        '  • Правильность электросхемы: ${commissioning['electricalScheme'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Правильность электросхемы']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Правильность электросхемы']}',
        );
      }

      buffer.writeln(
        '  • Отсутствие брака в компонентах: ${commissioning['componentsQuality'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Отсутствие брака в компонентах']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Отсутствие брака в компонентах']}',
        );
      }

      buffer.writeln(
        '  • Качество регулирования: ${commissioning['regulationQuality'] ?? 'Не проверено'}',
      );
      if (commissioningComments['Качество регулирования']?.isNotEmpty ??
          false) {
        buffer.writeln(
          '      Комментарий: ${commissioningComments['Качество регулирования']}',
        );
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

  Future<File> generateAndSavePdf({
    required String projectName,
    required DateTime reportTime,
    required String reportText,
  }) async {
    print('📄 Генерация PDF отчета...');

    await _loadFont();
    final font = _font ?? pw.Font.helvetica();

    final pdf = pw.Document();

    // Очищаем текст - убираем все лишние символы
    String cleanText = reportText;
    // Убираем эмодзи и спецсимволы
    cleanText = cleanText.replaceAll('✅', '[+]');
    cleanText = cleanText.replaceAll('❌', '[-]');
    cleanText = cleanText.replaceAll('📅', '');
    cleanText = cleanText.replaceAll('⏰', '');
    cleanText = cleanText.replaceAll('📂', '');
    cleanText = cleanText.replaceAll('💬', '');
    cleanText = cleanText.replaceAll('📊', '');
    cleanText = cleanText.replaceAll('⚡', '•');
    cleanText = cleanText.replaceAll('🔧', '•');
    cleanText = cleanText.replaceAll('📷', '');

    final lines = cleanText.split('\n');

    // Разбиваем текст на страницы
    final pages = _splitTextIntoPages(lines, font);

    // Добавляем каждую страницу
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
    final filename = 'Отчет_ИТП_$dateStr.pdf';

    // Сохраняем в Downloads
    String savePath;
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        savePath = '${downloadsDir.path}/$filename';
      } else {
        final documentsDir = Directory('/storage/emulated/0/Documents');
        if (await documentsDir.exists()) {
          savePath = '${documentsDir.path}/$filename';
        } else {
          savePath = '/storage/emulated/0/$filename';
        }
      }
    } catch (e) {
      final tempDir = Directory.systemTemp;
      savePath = '${tempDir.path}/$filename';
      print('⚠️ Использую временную директорию: $savePath');
    }

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());

    print('✅ PDF сохранен: $savePath (${pages.length} страниц)');
    return file;
  }

  List<List<String>> _splitTextIntoPages(List<String> allLines, pw.Font font) {
    final pages = <List<String>>[];
    List<String> currentPage = [];
    double currentHeight = 0;
    const double maxHeight = 750;

    // Начальная высота (заголовок)
    currentHeight = 100;

    for (final line in allLines) {
      if (line.trim().isEmpty && currentPage.isEmpty) {
        continue;
      }

      // Одинаковая высота для всех строк
      double lineHeight = 18;

      // Если это заголовок - чуть больше
      if (line.contains('АКТ') ||
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

      // Если это разделитель
      if (line.contains('=') || line.contains('-')) {
        lineHeight = 12;
      }

      // Если это пустая строка
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
          padding: const pw.EdgeInsets.all(16),
          color: PdfColors.blue,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'АКТ ПРОВЕРКИ',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'БЛОЧНОГО ТЕПЛОВОГО ПУНКТА',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                projectName,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                  font: font,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Дата формирования: ${DateFormat('dd.MM.yyyy HH:mm').format(reportTime)}',
                style: pw.TextStyle(
                  fontSize: 10,
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
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: font,
            ),
          ),
        ),
      );
      children.add(pw.SizedBox(height: 8));
    }

    // Добавляем все строки с одинаковым стилем
    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(pw.SizedBox(height: 6));
        continue;
      }

      // Определяем стиль для строки
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

      // Убираем лишние пробелы в начале
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

    // Номер страницы
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

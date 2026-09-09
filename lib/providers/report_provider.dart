import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../models/photo_record.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  ReportData? _currentReport;
  bool _isGenerating = false;
  String? _reportText;
  File? _pdfFile;

  // Хранилище для комментариев из электрики и ПНР
  Map<String, String> _electricalComments = {};
  Map<String, String> _commissioningComments = {};

  ReportData? get currentReport => _currentReport;
  bool get isGenerating => _isGenerating;
  String? get reportText => _reportText;
  File? get pdfFile => _pdfFile;

  void setElectricalComments(Map<String, String> comments) {
    _electricalComments = comments;
    notifyListeners();
  }

  void setCommissioningComments(Map<String, String> comments) {
    _commissioningComments = comments;
    notifyListeners();
  }

  Map<String, String> get electricalComments => _electricalComments;
  Map<String, String> get commissioningComments => _commissioningComments;

  Future<void> generateReport({
    required Map<String, List> checklistItems,
    required List<String> photoPaths,
    required List<String> photoDescriptions,
    required Map<String, dynamic> electricalData,
    required Map<String, dynamic> commissioningData,
  }) async {
    _isGenerating = true;
    notifyListeners();

    try {
      final electricalDataWithComments = Map<String, dynamic>.from(
        electricalData,
      );
      electricalDataWithComments['comments'] = _electricalComments;

      final commissioningDataWithComments = Map<String, dynamic>.from(
        commissioningData,
      );
      commissioningDataWithComments['comments'] = _commissioningComments;

      _currentReport = await _reportService.generateReport(
        checklistItems: checklistItems,
        photoPaths: photoPaths,
        photoDescriptions: photoDescriptions,
        electricalData: electricalDataWithComments,
        commissioningData: commissioningDataWithComments,
      );

      _reportText = _currentReport?.reportText;

      print('Отчет сгенерирован, длина текста: ${_reportText?.length ?? 0}');
    } catch (e) {
      print('Ошибка при генерации отчета: $e');
      _reportText = 'Ошибка при генерации отчета: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Сохранить отчет в PDF
  Future<void> savePdf({required String projectName}) async {
    if (_reportText == null || _reportText!.isEmpty) {
      throw Exception('Отчет не сгенерирован или пуст');
    }

    _pdfFile = await _reportService.generateAndSavePdf(
      projectName: projectName,
      reportTime: DateTime.now(),
      reportText: _reportText!,
    );

    notifyListeners();
  }

  // ========== НОВЫЙ МЕТОД ДЛЯ ОТПРАВКИ ОТЧЕТА С ФОТО ==========
  Future<void> shareReportWithPhotos(List<PhotoRecord> photos) async {
    if (_pdfFile == null) {
      throw Exception('PDF файл не найден. Сначала сохраните отчет.');
    }

    // Проверяем, существует ли файл
    if (!await _pdfFile!.exists()) {
      throw Exception('Файл отчета не найден на диске');
    }

    // Создаем список файлов для отправки
    final List<XFile> files = [];

    // Добавляем PDF
    files.add(XFile(_pdfFile!.path));

    // Добавляем фото, если они есть
    for (var photo in photos) {
      try {
        final file = File(photo.path);
        if (await file.exists()) {
          files.add(XFile(photo.path));
          print('✅ Добавлено фото: ${photo.description}');
        }
      } catch (e) {
        print('⚠️ Не удалось добавить фото: ${photo.description} - $e');
      }
    }

    // Формируем текст сообщения
    String text = '📄 Акт проверки блочного теплового пункта\n';
    text +=
        '📅 Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n\n';
    text += '📎 К отчету приложены фотоматериалы (${photos.length} шт.)\n';
    text += 'Отчет сгенерирован автоматически.';

    // Отправляем через share_plus
    await Share.shareXFiles(
      files,
      text: text,
      subject: 'Акт проверки теплового пункта',
    );
  }

  // Простая отправка только PDF
  Future<void> shareReport() async {
    if (_pdfFile == null) {
      throw Exception('PDF файл не найден. Сначала сохраните отчет.');
    }

    if (!await _pdfFile!.exists()) {
      throw Exception('Файл отчета не найден на диске');
    }

    await Share.shareXFiles(
      [XFile(_pdfFile!.path)],
      text:
          '📄 Акт проверки блочного теплового пункта\n'
          'Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n\n'
          'Отчет сгенерирован автоматически.',
      subject: 'Акт проверки теплового пункта',
    );
  }

  String? getPdfPath() {
    return _pdfFile?.path;
  }

  void resetReport() {
    _currentReport = null;
    _reportText = null;
    _pdfFile = null;
    _electricalComments = {};
    _commissioningComments = {};
    notifyListeners();
  }
}

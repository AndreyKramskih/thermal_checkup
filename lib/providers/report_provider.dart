import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report.dart';
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

  // Методы для сохранения комментариев
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
      // Добавляем комментарии в данные
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
      print(
        '📝 Комментарии электрики в отчете: ${_electricalComments.values.where((c) => c.isNotEmpty).length}',
      );
      print(
        '📝 Комментарии ПНР в отчете: ${_commissioningComments.values.where((c) => c.isNotEmpty).length}',
      );
    } catch (e) {
      print('Ошибка при генерации отчета: $e');
      _reportText = 'Ошибка при генерации отчета: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

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

  void resetReport() {
    _currentReport = null;
    _reportText = null;
    _pdfFile = null;
    _electricalComments = {};
    _commissioningComments = {};
    notifyListeners();
  }
}

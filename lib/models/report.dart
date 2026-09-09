import 'package:intl/intl.dart';

class ReportData {
  final String id;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  final String pdfPath;
  final String? reportText;

  ReportData({
    required this.id,
    required this.generatedAt,
    required this.data,
    required this.pdfPath,
    this.reportText,
  });

  String get formattedDate =>
      DateFormat('dd.MM.yyyy HH:mm').format(generatedAt);
}

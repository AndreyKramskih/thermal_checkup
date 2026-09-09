import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../providers/photo_provider.dart';
import '../providers/checklist_provider.dart';
import '../providers/report_provider.dart';
import '../providers/electrical_provider.dart';
import '../providers/commissioning_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _photoDescriptionController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PhotoProvider>(context, listen: false).loadPhotos();
    });
  }

  @override
  void dispose() {
    _photoDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChecklistProvider, PhotoProvider, ReportProvider>(
      builder: (context, checklistProvider, photoProvider, reportProvider, child) {
        return Column(
          children: [
            // Кнопка генерации отчета
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: reportProvider.isGenerating
                    ? null
                    : () {
                        _generateReport(
                          checklistProvider,
                          photoProvider,
                          reportProvider,
                          context,
                        );
                      },
                icon: reportProvider.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  reportProvider.isGenerating
                      ? 'Генерация...'
                      : 'Сгенерировать отчет',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            // Статус отчета
            if (reportProvider.currentReport != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '✅ Отчет сгенерирован',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '📅 ${reportProvider.currentReport!.formattedDate}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (reportProvider.pdfFile != null)
                              Text(
                                '📄 Размер: ${(reportProvider.pdfFile!.lengthSync() / 1024).round()} KB',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          _showReportPreview(reportProvider);
                        },
                      ),
                      // Кнопка "Сохранить PDF"
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          try {
                            await reportProvider.savePdf(projectName: 'ИТП №1');
                            final path = reportProvider.pdfFile?.path ?? '';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ PDF сохранен: $path'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.orange,
                      ),
                      // Кнопка "Поделиться PDF" (только отчет)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          try {
                            if (reportProvider.pdfFile == null) {
                              await reportProvider.savePdf(
                                projectName: 'ИТП №1',
                              );
                            }
                            await reportProvider.shareReport();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '📤 Открыто окно для отправки PDF',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.blue,
                      ),
                      // Кнопка "Поделиться PDF + Фото"
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () async {
                          try {
                            if (reportProvider.pdfFile == null) {
                              await reportProvider.savePdf(
                                projectName: 'ИТП №1',
                              );
                            }
                            await reportProvider.shareReportWithPhotos(
                              photoProvider.photos,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '📤 Открыто окно для отправки PDF + фото',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),

            // Список фото
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '📸 Фотоматериалы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${photoProvider.photos.length})',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Кнопки добавления фото
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _photoDescriptionController,
                      decoration: const InputDecoration(
                        hintText: '📝 Описание фото...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Кнопка камеры
                  IconButton.filled(
                    onPressed: () => _takePhoto(context, photoProvider),
                    icon: const Icon(Icons.camera_alt),
                    style: IconButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 4),
                  // Кнопка галереи
                  IconButton.filled(
                    onPressed: () => _pickFromGallery(context, photoProvider),
                    icon: const Icon(Icons.photo_library),
                    style: IconButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Список фото
            Expanded(
              child: photoProvider.photos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Нет добавленных фотографий',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'Добавьте фото с камеры или из галереи',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: photoProvider.photos.length,
                      itemBuilder: (context, index) {
                        final photo = photoProvider.photos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.photo,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        photo.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                        ).format(photo.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _showDeleteDialog(
                                      context,
                                      photoProvider,
                                      photo.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePhoto(
    BuildContext context,
    PhotoProvider photoProvider,
  ) async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Необходимо разрешение на использование камеры'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_photoDescriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Введите описание фото'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await photoProvider.addPhoto(file, _photoDescriptionController.text);
        _photoDescriptionController.clear();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Фото с камеры добавлено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFromGallery(
    BuildContext context,
    PhotoProvider photoProvider,
  ) async {
    try {
      if (_photoDescriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Введите описание фото'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await photoProvider.addPhoto(file, _photoDescriptionController.text);
        _photoDescriptionController.clear();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Фото из галереи добавлено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    PhotoProvider photoProvider,
    String photoId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              photoProvider.deletePhoto(photoId);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _generateReport(
    ChecklistProvider checklistProvider,
    PhotoProvider photoProvider,
    ReportProvider reportProvider,
    BuildContext context,
  ) {
    try {
      final electricalProvider = Provider.of<ElectricalProvider>(
        context,
        listen: false,
      );
      final commissioningProvider = Provider.of<CommissioningProvider>(
        context,
        listen: false,
      );

      reportProvider.setElectricalComments(electricalProvider.comments);
      reportProvider.setCommissioningComments(commissioningProvider.comments);

      final checklistData = checklistProvider.itemsByCategory;
      final photoPaths = photoProvider.photos.map((p) => p.path).toList();
      final photoDescriptions = photoProvider.photos
          .map((p) => p.description)
          .toList();

      final electricalItems = electricalProvider.items;
      final commissioningItems = commissioningProvider.items;

      final electricalDataForReport = {
        'sensors': electricalItems['Датчики подключены согласно схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'relays': electricalItems['Реле подключены согласно схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'pumps': electricalItems['Насосы подключены согласно схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'actuators':
            electricalItems['Привода подключены согласно схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'cableMarking':
            electricalItems['Кабеля промаркированы согласно схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'cableTypes': electricalItems['Тип кабелей соответствует схеме'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
      };

      final commissioningDataForReport = {
        'controllerProgram':
            commissioningItems['Работоспособность программы в контроллере'] ==
                true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'panelProgram':
            commissioningItems['Работоспособность программы в панели'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'cabinetAssembly':
            commissioningItems['Правильность сборки шкафа согласно схемы'] ==
                true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'electricalScheme':
            commissioningItems['Правильность электросхемы'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'componentsQuality':
            commissioningItems['Отсутствие брака в компонентах'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
        'regulationQuality':
            commissioningItems['Качество регулирования'] == true
            ? '✅ Выполнено'
            : '❌ Не выполнено',
      };

      reportProvider.generateReport(
        checklistItems: checklistData,
        photoPaths: photoPaths,
        photoDescriptions: photoDescriptions,
        electricalData: electricalDataForReport,
        commissioningData: commissioningDataForReport,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Генерация отчета начата...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Ошибка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReportPreview(ReportProvider reportProvider) {
    final reportText = reportProvider.reportText ?? 'Отчет пуст';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.blue),
              SizedBox(width: 8),
              Text('📄 Отчет'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 ${reportProvider.currentReport?.formattedDate ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        reportText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Текст отчета скопирован в буфер обмена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('📋 Копировать текст'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  if (reportProvider.pdfFile == null) {
                    await reportProvider.savePdf(projectName: 'ИТП №1');
                  }
                  await reportProvider.shareReport();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📤 Открыто окно для отправки PDF'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('📤 Поделиться PDF'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _shareWithPhotos(reportProvider);
              },
              child: const Text('📸 Поделиться PDF + фото'),
            ),
          ],
        );
      },
    );
  }

  void _shareWithPhotos(ReportProvider reportProvider) async {
    try {
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

      if (reportProvider.pdfFile == null) {
        await reportProvider.savePdf(projectName: 'ИТП №1');
      }

      await reportProvider.shareReportWithPhotos(photoProvider.photos);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Открыто окно для отправки PDF + фото'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/photo_record.dart';
import 'database_service.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final DatabaseService _db = DatabaseService();

  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Ошибка при съемке: $e');
    }
    return null;
  }

  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Ошибка при выборе фото: $e');
    }
    return null;
  }

  // ========== СОХРАНЕНИЕ С FALLBACK ==========
  Future<PhotoRecord> savePhoto(File imageFile, String description) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'photo_$timestamp';

    String safeName = _sanitizeFileName(description);
    if (safeName.isEmpty) {
      safeName = 'photo';
    }

    // ✅ FALLBACK: список путей по приоритету
    final List<String> possibleDirs = [
      '/storage/emulated/0/Pictures/thermal_checkup',
      '/storage/emulated/0/Download/thermal_checkup',
      '/storage/emulated/0/Documents/thermal_checkup',
      '/storage/emulated/0/Android/data/com.example.thermal_checkup/files',
      Directory.systemTemp.path,
    ];

    String? savedPath;
    final List<String> triedPaths = [];

    for (final dirPath in possibleDirs) {
      try {
        final dir = Directory(dirPath);
        triedPaths.add(dirPath);

        if (!await dir.exists()) {
          try {
            await dir.create(recursive: true);
          } catch (e) {
            print('⚠️ Не могу создать $dirPath: $e');
            continue;
          }
        }

        // Умная нумерация для уникальности
        String fileName = '$safeName.jpg';
        String fullPath = '$dirPath/$fileName';
        int counter = 1;

        while (await File(fullPath).exists()) {
          fileName = '${safeName}_$counter.jpg';
          fullPath = '$dirPath/$fileName';
          counter++;
          if (counter > 1000) {
            // Защита от бесконечного цикла
            break;
          }
        }

        // Копируем файл
        await imageFile.copy(fullPath);

        // Проверяем что файл реально скопировался
        final copiedFile = File(fullPath);
        if (await copiedFile.exists()) {
          final size = await copiedFile.length();
          if (size > 0) {
            savedPath = fullPath;
            print('✅ Фото сохранено: $fullPath (${(size / 1024).round()} KB)');
            break;
          } else {
            print('⚠️ Файл создан, но пустой: $fullPath');
          }
        }
      } catch (e) {
        print('⚠️ Ошибка при сохранении в $dirPath: $e');
        continue;
      }
    }

    // Fallback: если нигде не сохранилось — используем оригинальный путь
    if (savedPath == null) {
      savedPath = imageFile.path;
      print('⚠️ Все пути недоступны. Использую оригинальный путь: $savedPath');
      print('⚠️ Проверенные пути: ${triedPaths.join(", ")}');
    }

    final photo = PhotoRecord(
      id: id,
      path: savedPath,
      description: description,
      createdAt: DateTime.now(),
    );

    await _db.savePhoto(photo);
    return photo;
  }

  // Очищаем имя файла от недопустимых символов
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\u0400-\u04FF\-\.\(\)]'), '')
        .trim();
  }

  Future<List<PhotoRecord>> loadPhotos() async {
    return await _db.getPhotos();
  }

  Future<void> deletePhoto(String id) async {
    final photos = await _db.getPhotos();
    final photo = photos.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Фото не найдено'),
    );

    try {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Файл удален: ${photo.path}');
      }
    } catch (e) {
      print('⚠️ Ошибка при удалении файла: $e');
    }

    await _db.deletePhoto(id);
  }
}

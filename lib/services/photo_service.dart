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

  // ========== ГЛАВНОЕ: имя файла = только название пользователя ==========
  Future<PhotoRecord> savePhoto(File imageFile, String description) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'photo_$timestamp';

    // Формируем имя файла из описания
    String safeName = _sanitizeFileName(description);

    // Если описание пустое
    if (safeName.isEmpty) {
      safeName = 'photo';
    }

    // Определяем директорию для сохранения
    String appDirPath;
    try {
      final picturesDir = Directory('/storage/emulated/0/Pictures');
      if (await picturesDir.exists()) {
        appDirPath = '${picturesDir.path}/thermal_checkup';
      } else {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          appDirPath = '${downloadsDir.path}/thermal_checkup';
        } else {
          appDirPath = '/data/user/0/com.example.thermal_checkup/cache';
        }
      }

      final appDir = Directory(appDirPath);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
    } catch (e) {
      appDirPath = '/data/user/0/com.example.thermal_checkup/cache';
    }

    // ===== УМНАЯ НУМЕРАЦИЯ: если файл существует, добавляем (1), (2) и т.д. =====
    String fileName = '$safeName.jpg';
    String savedPath = '$appDirPath/$fileName';
    int counter = 1;

    while (await File(savedPath).exists()) {
      fileName = '$safeName($counter).jpg';
      savedPath = '$appDirPath/$fileName';
      counter++;
    }

    // Копируем файл
    try {
      await imageFile.copy(savedPath);
      print('✅ Фото сохранено: $savedPath');
    } catch (e) {
      savedPath = imageFile.path;
      print('⚠️ Не удалось скопировать файл: $e');
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
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Запрещенные символы
        .replaceAll(RegExp(r'\s+'), '_') // Пробелы на _
        .replaceAll(
          RegExp(r'[^\w\u0400-\u04FF\-\.\(\)]'),
          '',
        ) // Оставляем буквы, цифры, дефис, точку, кириллицу, скобки
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

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/photo_record.dart';
import 'database_service.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final DatabaseService _db = DatabaseService();

  // Сделать фото с камеры
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

  // Выбрать фото из галереи
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

  // Сохранить фото в постоянное хранилище (без path_provider)
  Future<PhotoRecord> savePhoto(File imageFile, String description) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'photo_$timestamp';
    final fileName = '$id.jpg';

    // Определяем путь для сохранения (прямые пути Android)
    String savedPath;

    try {
      // Пытаемся сохранить в Pictures/thermal_checkup/
      final picturesDir = Directory('/storage/emulated/0/Pictures');
      if (await picturesDir.exists()) {
        final appPicturesDir = Directory('${picturesDir.path}/thermal_checkup');
        if (!await appPicturesDir.exists()) {
          await appPicturesDir.create(recursive: true);
        }
        savedPath = '${appPicturesDir.path}/$fileName';
      } else {
        // Если Pictures нет, используем Downloads
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final appDownloadsDir = Directory(
            '${downloadsDir.path}/thermal_checkup',
          );
          if (!await appDownloadsDir.exists()) {
            await appDownloadsDir.create(recursive: true);
          }
          savedPath = '${appDownloadsDir.path}/$fileName';
        } else {
          // Если ничего нет - временная директория
          savedPath =
              '/data/user/0/com.example.thermal_checkup/cache/$fileName';
        }
      }
    } catch (e) {
      // Если ошибка, используем кэш
      savedPath = '/data/user/0/com.example.thermal_checkup/cache/$fileName';
      print('⚠️ Использую кэш: $savedPath');
    }

    // Копируем файл
    try {
      await imageFile.copy(savedPath);
      print('✅ Фото сохранено: $savedPath');
    } catch (e) {
      // Если не удалось скопировать, сохраняем только путь
      savedPath = imageFile.path;
      print(
        '⚠️ Не удалось скопировать файл, используем оригинальный путь: $savedPath',
      );
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

  // Загрузить все фото
  Future<List<PhotoRecord>> loadPhotos() async {
    return await _db.getPhotos();
  }

  // Удалить фото
  Future<void> deletePhoto(String id) async {
    // Получаем запись
    final photos = await _db.getPhotos();
    final photo = photos.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Фото не найдено'),
    );

    // Удаляем физический файл
    try {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Файл удален: ${photo.path}');
      }
    } catch (e) {
      print('⚠️ Ошибка при удалении файла: $e');
    }

    // Удаляем из БД
    await _db.deletePhoto(id);
  }
}

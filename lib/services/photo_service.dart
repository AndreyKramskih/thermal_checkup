import 'dart:io';
import '../models/photo_record.dart';
import 'database_service.dart';

class PhotoService {
  final DatabaseService _db = DatabaseService();

  // Сохранить фото (упрощенная версия без копирования файла)
  Future<PhotoRecord> savePhoto(File imageFile, String description) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = 'photo_$timestamp';

    final photo = PhotoRecord(
      id: id,
      path: imageFile.path, // Сохраняем оригинальный путь
      description: description,
      createdAt: DateTime.now(),
    );

    await _db.savePhoto(photo);
    return photo;
  }

  Future<List<PhotoRecord>> loadPhotos() async {
    return await _db.getPhotos();
  }

  Future<void> deletePhoto(String id) async {
    // Получаем запись
    final photos = await _db.getPhotos();
    final photo = photos.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Фото не найдено'),
    );

    // Пытаемся удалить физический файл
    try {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Ошибка при удалении файла: $e');
    }

    // Удаляем из БД
    await _db.deletePhoto(id);
  }
}

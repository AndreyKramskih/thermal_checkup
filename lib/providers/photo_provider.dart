import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_record.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final PhotoService _photoService = PhotoService();

  List<PhotoRecord> _photos = [];

  List<PhotoRecord> get photos => _photos;
  PhotoService get photoService => _photoService;

  Future<void> loadPhotos() async {
    _photos = await _db.getPhotos();
    notifyListeners();
  }

  Future<void> addPhoto(File imageFile, String description) async {
    final record = await _photoService.savePhoto(imageFile, description);
    _photos.add(record);
    notifyListeners();
  }

  Future<void> deletePhoto(String id) async {
    await _db.deletePhoto(id);
    _photos.removeWhere((photo) => photo.id == id);
    notifyListeners();
  }

  List<PhotoRecord> getPhotosForReport() {
    return _photos;
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_item.dart';
import '../models/photo_record.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _checklistKey = 'checklist_items';
  static const String _photosKey = 'photos';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Проверяем версию данных
    final currentVersion = _prefs.getString('checklist_version') ?? '0';
    final newVersion = '2.0'; // Новая версия с полным списком

    // Если версия не совпадает - пересоздаем данные
    if (currentVersion != newVersion) {
      print(
        '🔄 Обновление данных чек-листа с версии $currentVersion до $newVersion',
      );
      await _initChecklistData(force: true);
      await _prefs.setString('checklist_version', newVersion);
    } else if (!_prefs.containsKey(_checklistKey)) {
      await _initChecklistData();
    }
  }

  Future<void> _initChecklistData({bool force = false}) async {
    if (force) {
      // Удаляем старые данные
      await _prefs.remove(_checklistKey);
    }

    // Получаем данные из Constants
    final items = Constants.checklistData;
    final itemsJson = items.map((item) => item.toMap()).toList();
    await _prefs.setString(_checklistKey, jsonEncode(itemsJson));

    print('✅ Инициализировано ${items.length} пунктов чек-листа');
  }

  Future<Map<String, List<CheckItem>>> getChecklistItems() async {
    if (!_isInitialized) await initDatabase();

    final String? itemsJson = _prefs.getString(_checklistKey);
    if (itemsJson == null) return {};

    final List<dynamic> itemsList = jsonDecode(itemsJson);
    final List<CheckItem> items = itemsList
        .map((item) => CheckItem.fromMap(item as Map<String, dynamic>))
        .toList();

    Map<String, List<CheckItem>> result = {};
    for (var item in items) {
      if (!result.containsKey(item.category)) {
        result[item.category] = [];
      }
      result[item.category]!.add(item);
    }
    return result;
  }

  Future<void> updateChecklistItem(CheckItem updatedItem) async {
    if (!_isInitialized) await initDatabase();

    final String? itemsJson = _prefs.getString(_checklistKey);
    if (itemsJson == null) return;

    final List<dynamic> itemsList = jsonDecode(itemsJson);
    final List<Map<String, dynamic>> updatedList = [];

    for (var item in itemsList) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      if (map['id'] == updatedItem.id) {
        updatedList.add(updatedItem.toMap());
      } else {
        updatedList.add(map);
      }
    }

    await _prefs.setString(_checklistKey, jsonEncode(updatedList));
  }

  Future<void> savePhoto(PhotoRecord photo) async {
    if (!_isInitialized) await initDatabase();

    final String? photosJson = _prefs.getString(_photosKey);
    List<Map<String, dynamic>> photosList = [];
    if (photosJson != null) {
      photosList = List<Map<String, dynamic>>.from(jsonDecode(photosJson));
    }
    photosList.add(photo.toMap());
    await _prefs.setString(_photosKey, jsonEncode(photosList));
  }

  Future<List<PhotoRecord>> getPhotos() async {
    if (!_isInitialized) await initDatabase();

    final String? photosJson = _prefs.getString(_photosKey);
    if (photosJson == null) return [];

    final List<dynamic> photosList = jsonDecode(photosJson);
    return photosList
        .map((photo) => PhotoRecord.fromMap(photo as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePhoto(String id) async {
    if (!_isInitialized) await initDatabase();

    final String? photosJson = _prefs.getString(_photosKey);
    if (photosJson == null) return;

    final List<dynamic> photosList = jsonDecode(photosJson);
    final List<Map<String, dynamic>> updatedList = [];

    for (var photo in photosList) {
      final Map<String, dynamic> map = photo as Map<String, dynamic>;
      if (map['id'] != id) {
        updatedList.add(map);
      }
    }
    await _prefs.setString(_photosKey, jsonEncode(updatedList));
  }

  Future<void> resetAllData() async {
    if (!_isInitialized) await initDatabase();
    await _prefs.remove(_checklistKey);
    await _prefs.remove(_photosKey);
    await _prefs.remove('checklist_version');
    await _initChecklistData();
  }
}

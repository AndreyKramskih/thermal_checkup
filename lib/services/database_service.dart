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
  static const String _electricalKey = 'electrical_data';
  static const String _commissioningKey = 'commissioning_data';
  static const String _checklistVersionKey = 'checklist_version';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    final currentVersion = _prefs.getString(_checklistVersionKey) ?? '0';
    final newVersion = '2.0';

    if (currentVersion != newVersion) {
      print(
        '🔄 Обновление данных чек-листа с версии $currentVersion до $newVersion',
      );
      await _initChecklistData(force: true);
      await _prefs.setString(_checklistVersionKey, newVersion);
    } else if (!_prefs.containsKey(_checklistKey)) {
      await _initChecklistData();
    }
  }

  Future<void> _initChecklistData({bool force = false}) async {
    if (force) {
      await _prefs.remove(_checklistKey);
    }

    final items = Constants.checklistData;
    final itemsJson = items.map((item) => item.toMap()).toList();
    await _prefs.setString(_checklistKey, jsonEncode(itemsJson));

    print('✅ Инициализировано ${items.length} пунктов чек-листа');
  }

  // ========== ЧЕКЛИСТ ==========

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

  // ========== ФОТО ==========

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

  // ========== ЭЛЕКТРИКА (НОВОЕ!) ==========

  Future<void> saveElectricalData(Map<String, dynamic> data) async {
    if (!_isInitialized) await initDatabase();
    await _prefs.setString(_electricalKey, jsonEncode(data));
    print('💾 Данные электрики сохранены');
  }

  Future<Map<String, dynamic>?> getElectricalData() async {
    if (!_isInitialized) await initDatabase();

    final String? dataJson = _prefs.getString(_electricalKey);
    if (dataJson == null) return null;

    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  // ========== ПНР (НОВОЕ!) ==========

  Future<void> saveCommissioningData(Map<String, dynamic> data) async {
    if (!_isInitialized) await initDatabase();
    await _prefs.setString(_commissioningKey, jsonEncode(data));
    print('💾 Данные ПНР сохранены');
  }

  Future<Map<String, dynamic>?> getCommissioningData() async {
    if (!_isInitialized) await initDatabase();

    final String? dataJson = _prefs.getString(_commissioningKey);
    if (dataJson == null) return null;

    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  // ========== СБРОС ==========

  Future<void> resetAllData() async {
    if (!_isInitialized) await initDatabase();
    await _prefs.remove(_checklistKey);
    await _prefs.remove(_photosKey);
    await _prefs.remove(_electricalKey);
    await _prefs.remove(_commissioningKey);
    await _prefs.remove(_checklistVersionKey);
    await _initChecklistData();
  }
}

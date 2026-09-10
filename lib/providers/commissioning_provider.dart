import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:async';

class CommissioningProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  final Map<String, bool> _items = {
    'Работоспособность программы в контроллере': false,
    'Работоспособность программы в панели': false,
    'Правильность сборки шкафа согласно схемы': false,
    'Правильность электросхемы': false,
    'Отсутствие брака в компонентах': false,
    'Качество регулирования': false,
  };

  final Map<String, String> _comments = {};
  bool _isLoaded = false;
  Timer? _saveTimer;

  Map<String, bool> get items => _items;
  Map<String, String> get comments => _comments;
  bool get isLoaded => _isLoaded;

  CommissioningProvider() {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _db.getCommissioningData();
      if (data != null) {
        final itemsData = data['items'] as Map<String, dynamic>?;
        final commentsData = data['comments'] as Map<String, dynamic>?;

        if (itemsData != null) {
          for (final key in itemsData.keys) {
            _items[key] = itemsData[key] as bool? ?? false;
          }
        }
        if (commentsData != null) {
          for (final key in commentsData.keys) {
            _comments[key] = commentsData[key] as String? ?? '';
          }
        }
        print('✅ Данные ПНР загружены');
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('❌ Ошибка загрузки данных ПНР: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveData);
  }

  Future<void> _saveData() async {
    try {
      final data = {'items': Map.from(_items), 'comments': Map.from(_comments)};
      await _db.saveCommissioningData(data);
    } catch (e) {
      print('❌ Ошибка сохранения данных ПНР: $e');
    }
  }

  void toggleItem(String key, bool value) {
    _items[key] = value;
    notifyListeners();
    _scheduleSave();
  }

  void setComment(String key, String comment) {
    _comments[key] = comment;
    notifyListeners();
    _scheduleSave();
  }

  Map<String, dynamic> getData() {
    return {'items': Map.from(_items), 'comments': Map.from(_comments)};
  }

  Future<void> resetAll() async {
    _saveTimer?.cancel();
    for (final key in _items.keys) {
      _items[key] = false;
      _comments[key] = '';
    }
    notifyListeners();
    await _saveData();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

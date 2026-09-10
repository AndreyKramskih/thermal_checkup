import 'package:flutter/material.dart';
import '../services/database_service.dart';

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

  Map<String, bool> get items => _items;
  Map<String, String> get comments => _comments;
  bool get isLoaded => _isLoaded;

  CommissioningProvider() {
    loadData();
  }

  // Загрузка сохраненных данных
  Future<void> loadData() async {
    try {
      final data = await _db.getCommissioningData();
      if (data != null) {
        final itemsData = data['items'] as Map<String, dynamic>?;
        final commentsData = data['comments'] as Map<String, dynamic>?;

        if (itemsData != null) {
          for (var key in itemsData.keys) {
            _items[key] = itemsData[key] as bool? ?? false;
          }
        }

        if (commentsData != null) {
          for (var key in commentsData.keys) {
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

  // Сохранение данных
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
    _saveData(); // Автосохранение
  }

  void setComment(String key, String comment) {
    _comments[key] = comment;
    notifyListeners();
    _saveData(); // Автосохранение
  }

  Map<String, dynamic> getData() {
    return {'items': Map.from(_items), 'comments': Map.from(_comments)};
  }

  Future<void> resetAll() async {
    for (var key in _items.keys) {
      _items[key] = false;
      _comments[key] = '';
    }
    notifyListeners();
    await _saveData();
  }
}

import 'package:flutter/material.dart';
import '../models/check_item.dart';
import '../services/database_service.dart';

class ChecklistProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Map<String, List<CheckItem>> _itemsByCategory = {};
  Map<String, bool> _categoryStatus = {};

  Map<String, List<CheckItem>> get itemsByCategory => _itemsByCategory;
  Map<String, bool> get categoryStatus => _categoryStatus;

  // Загрузка данных из БД
  Future<void> loadChecklist() async {
    _itemsByCategory = await _db.getChecklistItems();
    _updateCategoryStatus();
    notifyListeners();
  }

  void _updateCategoryStatus() {
    for (var entry in _itemsByCategory.entries) {
      final items = entry.value;
      if (items.isEmpty) {
        _categoryStatus[entry.key] = false;
      } else {
        _categoryStatus[entry.key] = items.every((item) => item.isChecked);
      }
    }
  }

  // Переключение статуса пункта
  Future<void> toggleItem(String category, int index) async {
    final item = _itemsByCategory[category]?[index];
    if (item != null) {
      item.isChecked = !item.isChecked;
      await _db.updateChecklistItem(item);
      _updateCategoryStatus();
      notifyListeners();
    }
  }

  // Добавление комментария
  Future<void> addComment(String category, int index, String comment) async {
    final item = _itemsByCategory[category]?[index];
    if (item != null) {
      item.comment = comment;
      await _db.updateChecklistItem(item);
      notifyListeners();
    }
  }

  // Получение прогресса
  double getProgress() {
    int total = 0;
    int checked = 0;

    for (var items in _itemsByCategory.values) {
      total += items.length;
      checked += items.where((item) => item.isChecked).length;
    }

    return total > 0 ? checked / total : 0;
  }

  // Сброс всех данных
  Future<void> resetAll() async {
    await _db.resetAllData();
    await loadChecklist();
  }
}

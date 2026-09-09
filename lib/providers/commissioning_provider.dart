import 'package:flutter/material.dart';

class CommissioningProvider extends ChangeNotifier {
  final Map<String, bool> _items = {
    'Работоспособность программы в контроллере': false,
    'Работоспособность программы в панели': false,
    'Правильность сборки шкафа согласно схемы': false,
    'Правильность электросхемы': false,
    'Отсутствие брака в компонентах': false,
    'Качество регулирования': false,
  };

  final Map<String, String> _comments = {};

  Map<String, bool> get items => _items;
  Map<String, String> get comments => _comments;

  void toggleItem(String key, bool value) {
    _items[key] = value;
    notifyListeners();
  }

  void setComment(String key, String comment) {
    _comments[key] = comment;
    notifyListeners();
  }

  Map<String, dynamic> getData() {
    return {'items': Map.from(_items), 'comments': Map.from(_comments)};
  }

  void resetAll() {
    for (var key in _items.keys) {
      _items[key] = false;
      _comments[key] = '';
    }
    notifyListeners();
  }
}

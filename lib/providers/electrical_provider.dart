import 'package:flutter/material.dart';

class ElectricalProvider extends ChangeNotifier {
  final Map<String, bool> _items = {
    'Датчики подключены согласно схеме': false,
    'Реле подключены согласно схеме': false,
    'Насосы подключены согласно схеме': false,
    'Привода подключены согласно схеме': false,
    'Кабеля промаркированы согласно схеме': false,
    'Тип кабелей соответствует схеме': false,
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

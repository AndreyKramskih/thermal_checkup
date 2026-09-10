import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectProvider extends ChangeNotifier {
  static const String _projectNameKey = 'project_name';

  String _projectName = 'ИТП №1';

  String get projectName => _projectName;

  ProjectProvider() {
    _loadProjectName();
  }

  Future<void> _loadProjectName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_projectNameKey);
      if (savedName != null && savedName.isNotEmpty) {
        _projectName = savedName;
        notifyListeners();
      }
    } catch (e) {
      print('Ошибка загрузки названия проекта: $e');
    }
  }

  Future<void> setProjectName(String name) async {
    if (name.trim().isEmpty) return;

    _projectName = name.trim();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_projectNameKey, _projectName);
    } catch (e) {
      print('Ошибка сохранения названия проекта: $e');
    }
  }
}

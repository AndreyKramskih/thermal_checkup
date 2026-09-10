import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/report_provider.dart';
import '../providers/electrical_provider.dart';
import '../providers/commissioning_provider.dart';
import 'categories_screen.dart';
import 'electrical_screen.dart';
import 'commissioning_screen.dart';
import 'report_screen.dart';
import 'project_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CategoriesScreen(),
    const ElectricalScreen(),
    const CommissioningScreen(),
    const ReportScreen(),
  ];

  final List<String> _titles = [
    'Проверка монтажа',
    'Электромонтаж',
    'ПНР',
    'Отчет',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Provider.of<ChecklistProvider>(
      context,
      listen: false,
    ).loadChecklist();
    await Provider.of<PhotoProvider>(context, listen: false).loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProjectSettingsScreen(),
                ),
              );
            },
            tooltip: 'Настройки проекта',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Монтаж'),
          BottomNavigationBarItem(
            icon: Icon(Icons.electrical_services),
            label: 'Электрика',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ПНР'),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Отчет',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showResetDialog();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Сброс'),
            )
          : null,
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить все данные?'),
        content: const Text(
          'Будут сброшены:\n'
          '• Все отметки в чек-листе\n'
          '• Все комментарии монтажа\n'
          '• Все данные электромонтажа\n'
          '• Все данные ПНР\n'
          '• Все фотографии\n\n'
          'Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Все данные сброшены'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== МЕТОД ПОЛНОГО СБРОСА =====
  Future<void> _resetAllData() async {
    // 1. Сброс чек-листа монтажа
    await Provider.of<ChecklistProvider>(context, listen: false).resetAll();

    // 2. Сброс данных электромонтажа
    await Provider.of<ElectricalProvider>(context, listen: false).resetAll();

    // 3. Сброс данных ПНР
    await Provider.of<CommissioningProvider>(context, listen: false).resetAll();

    // 4. Сброс данных отчета
    Provider.of<ReportProvider>(context, listen: false).resetReport();

    // 5. Перезагрузка фото (они удаляются отдельно через UI)
    await Provider.of<PhotoProvider>(context, listen: false).loadPhotos();
  }
}

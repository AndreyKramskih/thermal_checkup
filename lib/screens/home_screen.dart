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
    // Загружаем данные ПОСЛЕ первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  // ===== ЗАГРУЗКА ДАННЫХ =====
  // Захватываем провайдеры ДО await, чтобы не использовать context после async gap
  Future<void> _loadData() async {
    try {
      final checklistProvider = Provider.of<ChecklistProvider>(
        context,
        listen: false,
      );
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

      await checklistProvider.loadChecklist();
      await photoProvider.loadPhotos();

      debugPrint(
        '🟢 _loadData: всё загружено (${checklistProvider.itemsByCategory.length} категорий)',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ _loadData ошибка: $e');
      debugPrint('Стек: $stackTrace');
    }
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

  // ===== ДИАЛОГ СБРОСА =====
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _resetAllData();

              // Проверяем State.mounted (не dialogContext — диалог уже закрыт)
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Все данные сброшены'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== ПОЛНЫЙ СБРОС =====
  // Захватываем ВСЕ провайдеры ДО первого await
  Future<void> _resetAllData() async {
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final electricalProvider = Provider.of<ElectricalProvider>(
      context,
      listen: false,
    );
    final commissioningProvider = Provider.of<CommissioningProvider>(
      context,
      listen: false,
    );
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    // Теперь безопасно вызываем async-методы
    await checklistProvider.resetAll();
    await electricalProvider.resetAll();
    await commissioningProvider.resetAll();
    reportProvider.resetReport();
    await photoProvider.loadPhotos();
  }
}

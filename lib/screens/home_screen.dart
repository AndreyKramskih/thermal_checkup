import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import '../providers/photo_provider.dart';
// import '../providers/report_provider.dart';
import 'categories_screen.dart';
import 'electrical_screen.dart';
import 'commissioning_screen.dart';
import 'report_screen.dart'; // Убедитесь, что этот импорт есть

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
    const ReportScreen(), // <-- Здесь ошибка, если ReportScreen не найден
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
        title: const Text('Сбросить данные?'),
        content: const Text('Все данные проверки будут сброшены. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<ChecklistProvider>(
                context,
                listen: false,
              ).resetAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Данные сброшены'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

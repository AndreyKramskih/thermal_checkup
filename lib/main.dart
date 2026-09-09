import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/photo_provider.dart';
import 'providers/report_provider.dart';
import 'providers/electrical_provider.dart';
import 'providers/commissioning_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация базы данных
  final dbService = DatabaseService();
  await dbService.initDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ElectricalProvider()),
        ChangeNotifierProvider(create: (_) => CommissioningProvider()),
      ],
      child: MaterialApp(
        title: 'Тепловой пункт - Проверка',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/electrical_provider.dart';

class ElectricalScreen extends StatefulWidget {
  const ElectricalScreen({super.key});

  @override
  State<ElectricalScreen> createState() => _ElectricalScreenState();
}

class _ElectricalScreenState extends State<ElectricalScreen> {
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры СРАЗУ для всех ключей провайдера.
    // Провайдер создаётся в MultiProvider до первого build этого экрана,
    // поэтому его items.keys уже доступны.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initControllers();
    });
  }

  void _initControllers() {
    final provider = Provider.of<ElectricalProvider>(context, listen: false);
    for (final key in provider.items.keys) {
      _commentControllers.putIfAbsent(
        key,
        () => TextEditingController(text: provider.comments[key] ?? ''),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElectricalProvider>(
      builder: (context, provider, child) {
        // Пока контроллеры не готовы — показываем загрузку.
        if (_commentControllers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Проверка электромонтажа',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Проверьте соответствие подключения всех элементов согласно электрической схеме',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...provider.items.keys.map((title) {
                final bool value = provider.items[title] ?? false;
                final controller = _commentControllers[title]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: value,
                              onChanged: (newValue) {
                                provider.toggleItem(title, newValue ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: TextField(
                            controller: controller,
                            onChanged: (text) {
                              provider.setComment(title, text);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Комментарий...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _ProgressCard(provider: provider),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ElectricalProvider provider;

  const _ProgressCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final completed = provider.items.values.where((v) => v == true).length;
    final total = provider.items.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прогресс проверки электромонтажа',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выполнено: $completed из $total',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

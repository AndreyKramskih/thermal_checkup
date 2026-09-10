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
    // Инициализация контроллеров после загрузки данных
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
    });
  }

  void _initControllers() {
    final provider = Provider.of<ElectricalProvider>(context, listen: false);
    for (var key in provider.items.keys) {
      if (!_commentControllers.containsKey(key)) {
        _commentControllers[key] = TextEditingController(
          text: provider.comments[key] ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ElectricalProvider>(
      builder: (context, provider, child) {
        // Инициализируем контроллеры если еще не сделали
        if (_commentControllers.isEmpty) {
          _initControllers();
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

                // Убеждаемся что контроллер существует
                if (!_commentControllers.containsKey(title)) {
                  _commentControllers[title] = TextEditingController(
                    text: provider.comments[title] ?? '',
                  );
                }

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
                            controller: _commentControllers[title],
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
              }).toList(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final completedCount = provider.items.values
                      .where((v) => v == true)
                      .length;
                  final totalCount = provider.items.length;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Сохранено! Выполнено $completedCount из $totalCount пунктов',
                      ),
                      backgroundColor: completedCount == totalCount
                          ? Colors.green
                          : Colors.blue,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Сохранить результаты'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Прогресс проверки электромонтажа',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Выполнено: ${provider.items.values.where((v) => v == true).length} из ${provider.items.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${(provider.items.values.where((v) => v == true).length / provider.items.length * 100).round()}%',
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
                        value:
                            provider.items.values
                                .where((v) => v == true)
                                .length /
                            provider.items.length,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

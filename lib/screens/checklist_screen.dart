import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/check_item.dart';
import '../providers/checklist_provider.dart';

class ChecklistScreen extends StatefulWidget {
  final String category;
  final List<CheckItem> items;

  const ChecklistScreen({
    super.key,
    required this.category,
    required this.items,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChecklistProvider>(
      builder: (context, provider, child) {
        // Получаем актуальные данные из провайдера
        final currentItems = provider.itemsByCategory[widget.category] ?? [];

        return Scaffold(
          appBar: AppBar(title: Text(widget.category)),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: currentItems.length,
            itemBuilder: (context, index) {
              final item = currentItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Checkbox(
                        value: item.isChecked,
                        onChanged: (_) async {
                          // Используем setState для обновления UI
                          setState(() {
                            // Изменяем состояние локально
                          });
                          // Обновляем в провайдере
                          await provider.toggleItem(widget.category, index);
                        },
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: item.isChecked ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: item.description.isNotEmpty
                          ? Text(
                              item.description,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.comment, size: 20),
                        onPressed: () {
                          _showCommentDialog(
                            context,
                            provider,
                            widget.category,
                            index,
                          );
                        },
                      ),
                    ),
                    if (item.comment != null && item.comment!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.comment,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.comment!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCommentDialog(
    BuildContext context,
    ChecklistProvider provider,
    String category,
    int index,
  ) {
    final items = provider.itemsByCategory[category] ?? [];
    final currentComment = items[index].comment;

    showDialog(
      context: context,
      builder: (dialogContext) => _CommentDialog(
        initialComment: currentComment,
        onSave: (comment) async {
          await provider.addComment(category, index, comment);
        },
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final String? initialComment;
  final Future<void> Function(String) onSave;

  const _CommentDialog({required this.initialComment, required this.onSave});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Комментарий'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Введите комментарий...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () async {
            await widget.onSave(_controller.text);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

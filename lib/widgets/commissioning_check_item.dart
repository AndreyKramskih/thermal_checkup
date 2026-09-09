import 'package:flutter/material.dart';

class CommissioningCheckItem extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextEditingController commentController;
  final TextEditingController valueController;

  const CommissioningCheckItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.commentController,
    required this.valueController,
  });

  @override
  Widget build(BuildContext context) {
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
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: [
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      hintText: 'Значение/результат...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: commentController,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

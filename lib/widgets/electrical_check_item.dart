import 'package:flutter/material.dart';

class ElectricalCheckItem extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextEditingController commentController;

  const ElectricalCheckItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.commentController,
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
              child: TextField(
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
            ),
          ],
        ),
      ),
    );
  }
}

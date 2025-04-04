import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final String task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const TaskItem({
    Key? key,
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                task,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Checkbox(
              value: isCompleted,
              onChanged: (value) => onToggle(),
              activeColor: const Color(0xFFFFEE58), // Medium yellow
            ),
          ],
        ),
      ),
    );
  }
}
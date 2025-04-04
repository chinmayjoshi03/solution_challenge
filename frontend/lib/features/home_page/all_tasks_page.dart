import 'package:flutter/material.dart';
import 'package:solution_challenge/features/home_page/task_item.dart';

class AllTasksPage extends StatelessWidget {
  final List<String> tasks;
  final List<bool> taskCompletion;
  final Function(int) onToggleTask;

  const AllTasksPage({
    Key? key,
    required this.tasks,
    required this.taskCompletion,
    required this.onToggleTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4), // Light yellow background
      appBar: AppBar(
        title: const Text("All Daily Tasks", style: TextStyle(color: Colors.black87)),
        backgroundColor: const Color(0xFFFFDE03),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return TaskItem(
            task: tasks[index],
            isCompleted: taskCompletion[index],
            onToggle: () {
              onToggleTask(index); // Call parent function to handle state update
            },
          );
        },
      ),
    );
  }
}

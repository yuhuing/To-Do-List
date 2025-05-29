import 'package:flutter/material.dart';
import 'TaskModel.dart';

class HistoryPage extends StatelessWidget {
  final List<Task> tasks;

  const HistoryPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3D9),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF6F4E37),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: tasks.isEmpty
            ? const Center(
                child: Text(
                  "No history tasks yet.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    color: const Color(0xFFF3E5AB),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 18,
                          color: Colors.brown[900],
                        ),
                      ),
                      subtitle: Text(
                        task.details,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: const Icon(Icons.warning, color: Colors.red),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

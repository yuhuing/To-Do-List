// TodayTask.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'HistoryPage.dart';
import 'TaskModel.dart';
import 'AppDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodayTask(username: 'TestUser'),
    );
  }
}

class TodayTask extends StatefulWidget {
  final String username;
  const TodayTask({super.key, required this.username});

  @override
  State<TodayTask> createState() => _TodayTaskState();
}

class _TodayTaskState extends State<TodayTask> {
  List<Task> todayTasks = [];
  List<Task> historyTasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  late Timer _midnightTimer;
  bool _midnightHandled = false;

  void _confirmDeleteTask(int index) {
  showDialog(
    
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        "Delete Task",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
      content: const Text("Are you sure you want to delete this task?"),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.brown[400], 
          ),
          onPressed: () => Navigator.of(context).pop(), // Cancel
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF990000),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            setState(() {
              todayTasks.removeAt(index);
            });
            Navigator.of(context).pop(); // Close dialog
          },
          child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMidnightHandled().then((_) {
      final now = DateTime.now().toUtc().add(const Duration(hours: 8));
      final todayMidnight = DateTime(now.year, now.month, now.day);
      if (now.isAfter(todayMidnight) && !_midnightHandled) {
        _handleMidnight();
      }
      _scheduleMidnightCheck();
    });
  }

  void _scheduleMidnightCheck() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final diff = nextMidnight.difference(now);
    _midnightTimer = Timer(diff, _handleMidnight);
  }

  Future<void> _loadMidnightHandled() async {
    final prefs = await SharedPreferences.getInstance();
    final lastHandledDate = prefs.getString('lastHandledDate');
    final nowDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 8)));
    
    if (lastHandledDate != nowDate) {
      _midnightHandled = false; // It's a new day, reset the state
      await prefs.setString('lastHandledDate', nowDate);
      await prefs.setBool('midnightHandled', false);
    } 
    
    else {
      _midnightHandled = prefs.getBool('midnightHandled') ?? false;
    }
  }

  void _handleMidnight() async {
    if (_midnightHandled) return;
    
    setState(() {
      historyTasks.addAll(todayTasks.where((task) => !task.isDone));
      todayTasks.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final nowDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 8)));
    await prefs.setBool('midnightHandled', true);
    await prefs.setString('lastHandledDate', nowDate);

    _midnightHandled = true;
    _scheduleMidnightCheck();
  }

  void _addTask(String title, String details) {
    setState(() {
      todayTasks.add(Task(title: title, details: details, dueDate: DateTime.now(), isDone: false));
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
  }

  @override
  void dispose() {
    _midnightTimer.cancel();
    _taskController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Task",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 16),
              
              // Task title input
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  labelText: "Task Title",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              
              // Details input with scrollable box
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _detailsController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Details",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_taskController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Task title cannot be empty."),
                            backgroundColor:Color(0xFFDE0A26),
                          ),
                        );
                        return;
                      }

                      _addTask(_taskController.text.trim(), _detailsController.text.trim());
                      _taskController.clear();
                      _detailsController.clear();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().toUtc().add(const Duration(hours: 8)));

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown, size: 32),
      ),

      drawer: const AppDrawer(),

      body: Stack(
      children: [
        // *** 放大后的 Menu 按钮
        
        // SafeArea(
        //   child: Align(
        //     alignment: Alignment.topLeft,
        //     child: Builder(
        //       builder: (context) => Container(
        //         margin: const EdgeInsets.only(left: 12, top: 8),
        //         child: IconButton(
        //           icon: const Icon(Icons.menu),
        //           color: Colors.brown,
        //           iconSize: 36,
        //           onPressed: () {
        //             Scaffold.of(context).openDrawer();
        //           },
        //         ),
        //       ),
        //     ),
        //   ),
        // ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Today's Task",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),

            const SizedBox(height: 40),
                
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        "Date: $todayDate",
                        style: const TextStyle(fontSize: 14, color: Colors.brown),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    if(todayTasks.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            "No tasks for today",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else    
                      Expanded(
                        child: ListView.builder(
                              //shrinkWrap: true,
                              //physics: const NeverScrollableScrollPhysics(),
                              itemCount: todayTasks.length,
                              itemBuilder: (context, index) {
                                final task = todayTasks[index];
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
                                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                                        fontSize: 18,
                                        color: Colors.brown[900],
                                      ),
                                    ),
                                    subtitle: Text(task.details),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                            color: task.isDone ? Colors.green : Colors.brown,
                                          ),
                                          onPressed: () => _toggleTaskCompletion(task),
                                        ),

                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Color(0xFF990000)),
                                          tooltip: 'Delete Task',
                                          onPressed: () => _confirmDeleteTask(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
  
      Positioned(
        top: 50,
        right: 20,
        child: IconButton(
          icon: const Icon(Icons.history, color: Colors.brown),
          tooltip: "View History",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryPage(tasks: historyTasks),
              ),
            );
          },
        ),
      ),

      ],
    ),
      
  floatingActionButton: Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: FloatingActionButton(
      backgroundColor: Colors.brown,
      onPressed: _showAddTaskDialog,
      child: const Icon(Icons.add, size: 30),
    ),
  ),

  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

  }
}

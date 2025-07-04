// TodayTask.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../screens/TaskProvider.dart';
import '../screens/HistoryPage.dart';
import '../screens/TaskModel.dart';
import '../screens/MidnightTaskService.dart';
import '../widgets/AppDrawer.dart';

class TodayTask extends StatefulWidget {
  const TodayTask({super.key});

  @override
  State<TodayTask> createState() => _TodayTaskState();
}

class _TodayTaskState extends State<TodayTask> {
  Timer? _statusTimer;
  String _midnightStatus = '';
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Color constants matching PersonalProfile
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color coffeeShadow = Color(0x1A2C1810);

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _startStatusMonitoring();
  }

  // 🔧 添加统一的马来西亚时间方法
  // DateTime _getMalaysiaTime() {
  //   return DateTime.now().toUtc().add(const Duration(hours: 8));
  // }

  // DateTime _getMalaysiaDateKey() {
  //   final malaysiaTime = _getMalaysiaTime();
  //   return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  // }

  // 🔧 FIXED: Create date-only DateTime for today's tasks (debug)
  // DateTime _getTodayMidnight() {
  //   final malaysiaTime = _getMalaysiaTime();
  //   return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  // }

  DateTime _getMalaysiaTime() {
    return DateTime.now();
  }

  DateTime _getMalaysiaDateKey() {
    // final malaysiaTime = _getMalaysiaTime();
    return DateTime(
      _getMalaysiaTime().year,
      _getMalaysiaTime().month,
      _getMalaysiaTime().day,
    );
  }

  // 🔧 FIXED: Create date-only DateTime for today's tasks (debug)
  DateTime _getTodayMidnight() {
    // final malaysiaTime = _getMalaysiaTime();
    return DateTime(
      _getMalaysiaTime().year,
      _getMalaysiaTime().month,
      _getMalaysiaTime().day,
    );
  }

  // 添加状态监控方法
  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          final timeUntilMidnight = MidnightTaskService.getTimeUntilMidnight();
          final hours = timeUntilMidnight.inHours;
          final minutes = timeUntilMidnight.inMinutes % 60;
          final seconds = timeUntilMidnight.inSeconds % 60;

          _midnightStatus =
              'Next midnight in: ${hours}h ${minutes}m ${seconds}s\n'
              'Handled today: ${MidnightTaskService.isMidnightHandled}';
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _taskController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // Initialize app with Firebase tasks and midnight handling
  Future<void> _initializeApp() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      // Initialize tasks from Firebase
      await taskProvider.initializeTasks();

      // Set up real-time listener
      await MidnightTaskService.initialize(context);
    } catch (e) {
      print('Error initializing app: $e');
    }
  }

  // Task operations - Updated to use async methods
  Future<void> _addTask(String title, String details) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = Task(
      title: title,
      details: details,
      dueDate: _getTodayMidnight(), // debug
      isDone: false,
      priority: Priority.high, // Default priority
    );

    try {
      print('Adding task: $title, dueDate: ${task.dueDate}');
      await taskProvider.addTask(task);
      print('Task successfully added to provider');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding task: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      await taskProvider.toggleTaskDoneWithConfirmation(context, task);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating task: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteTask(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 370, minWidth: 370),
              child: AlertDialog(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Task',
                      style: TextStyle(
                        color: espresso,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete this task?',
                  style: TextStyle(
                    color: coffeeBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: coffeeBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).removeTask(task);
                        if (mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error deleting task: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Common validation helper
  bool _validateTaskTitle() {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Task title cannot be empty",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          // behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // margin: EdgeInsets.all(16),
          elevation: 6,
        ),
      );
      return false;
    }
    return true;
  }

  // Common function to clear controllers and close dialog
  void _clearAndClose() {
    _taskController.clear();
    _detailsController.clear();
    Navigator.of(context).pop();
  }

  // Common dialog container
  Widget _buildDialogContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: coffeeShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: espresso,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDialog({
    required TextEditingController titleController,
    required TextEditingController detailsController,
    required VoidCallback onSave,
    required String saveButtonText,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16), // Add padding to prevent overflow ***
      child: Container(
        // Add constraints to prevent dialog from being too large ***
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.8, // Limit height to 80% of screen ***
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [creamWhite, milkFoam],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: coffeeShadow,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            // Wrap content in SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with coffee bean icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: coffeeBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.coffee, color: coffeeBrown, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      saveButtonText == "Update Task"
                          ? "Edit Task"
                          : "New Task",
                      style: TextStyle(
                        color: espresso,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Title field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: coffeeShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "What's your coffee order?",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.emoji_food_beverage,
                        color: caramelBrown,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Details field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: coffeeShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add some details...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(16),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.receipt_long, color: caramelBrown),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _clearAndClose,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [coffeeBrown, caramelBrown],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: coffeeBrown.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: onSave,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  saveButtonText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _buildTaskDialog(
            titleController: _taskController,
            detailsController: _detailsController,
            onSave: _handleAddTask,
            saveButtonText: "Add Task",
          ),
    );
  }

  void _showEditTaskDialog(Task task) {
    _taskController.text = task.title;
    _detailsController.text = task.details;

    showDialog(
      context: context,
      builder:
          (context) => _buildTaskDialog(
            titleController: _taskController,
            detailsController: _detailsController,
            onSave: () => _handleEditTask(task),
            saveButtonText: "Update Task",
          ),
    );
  }

  void _handleAddTask() async {
    if (!_validateTaskTitle()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
              ),
            ),
          ),
    );

    try {
      await _addTask(
        _taskController.text.trim(),
        _detailsController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _clearAndClose(); // Close add task dialog
        // // Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("Task added successfully!"),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        //);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        print('Failed to add task: $e');
      }
    }
  }

  void _handleEditTask(Task task) async {
    if (!_validateTaskTitle()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
              ),
            ),
          ),
    );

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    try {
      await taskProvider.updateTask(
        task,
        title: _taskController.text.trim(),
        details: _detailsController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _clearAndClose(); // Close edit dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating task: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI Builders
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: coffeeBrown),
        filled: true,
        fillColor: milkFoam,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: caramelBrown, width: 2),
        ),
      ),
    );
  }

  Widget _buildDetailsField() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: milkFoam,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: _detailsController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: "Task details (optional)",
          hintStyle: TextStyle(color: coffeeBrown.withOpacity(0.6)),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: milkFoam,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: coffeeShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: task.isDone ? Colors.grey[500] : espresso,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey[500],
                      decorationThickness: 2,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IconButton(
                    //   icon: Icon(
                    //     Icons.edit_outlined,
                    //     color: caramelBrown,
                    //     size: 20,
                    //   ),
                    //   onPressed: () => _showEditTaskDialog(task),
                    //   constraints: const BoxConstraints(),
                    //   padding: const EdgeInsets.all(8),
                    // ),
                    // IconButton(
                    //   icon: Icon(
                    //     task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    //     color: task.isDone ? Colors.green : coffeeBrown,
                    //     size: 24,
                    //   ),
                    //   onPressed: () => Provider.of<TaskProvider>(context, listen: false).toggleTaskDoneWithConfirmation(context, task),
                    //   constraints: const BoxConstraints(),
                    //   padding: const EdgeInsets.all(8),
                    // ),
                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.delete_outline,
                    //     color: Colors.red,
                    //     size: 20,
                    //   ),
                    //   onPressed: () => _confirmDeleteTask(task),
                    //   constraints: const BoxConstraints(),
                    //   padding: const EdgeInsets.all(8),
                    // ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditTaskDialog(task),
                      color: caramelBrown,
                      tooltip: "Edit",
                    ),
                    IconButton(
                      icon: Icon(
                        task.isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task.isDone ? Colors.green : coffeeBrown,
                        size: 24,
                      ),
                      onPressed:
                          () => Provider.of<TaskProvider>(
                            context,
                            listen: false,
                          ).toggleTaskDoneWithConfirmation(context, task),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDeleteTask(task),
                      color: Colors.red[700],
                      tooltip: "Delete",
                    ),
                  ],
                ),
              ],
            ),
            if (task.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.details,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Show loading indicator while tasks are being loaded
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
            ),
          );
        }

        final todayTasks = taskProvider.getTasksFor(_getMalaysiaDateKey());

        if (todayTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: coffeeBrown.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No tasks for today",
                  style: TextStyle(
                    fontSize: 18,
                    color: coffeeBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap the + button to add a new task",
                  style: TextStyle(
                    fontSize: 14,
                    color: coffeeBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: todayTasks.length,
          itemBuilder: (context, index) => _buildTaskCard(todayTasks[index]),
        );
      },
    );
  }

  Widget _buildDebugInfo() {
    if (_midnightStatus.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            _midnightStatus,
            style: const TextStyle(fontSize: 11, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Malaysia Time: ${DateFormat('HH:mm:ss').format(_getMalaysiaTime())}',
            style: const TextStyle(fontSize: 10, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateFormat(
      'EEEE, MMM dd, yyyy',
    ).format(_getMalaysiaTime());

    return Scaffold(
      backgroundColor: creamWhite,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.coffee, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Today's Tasks",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: espresso,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [espresso, coffeeBrown],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.history, size: 20),
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryPage()),
                    ),
                tooltip: "View History",
              ),
              // Notification badge
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return FutureBuilder<int>(
                    future: taskProvider.getNonDeletedHistoryTasksCount(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == 0) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            snapshot.data! > 99
                                ? '99+'
                                : snapshot.data!.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: coffeeShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, color: caramelBrown, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      todayDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: espresso,
                      ),
                    ),
                  ],
                ),
              ),

              // pattern: https://claude.ai/chat/357b05fc-316d-4949-92b7-d47d0711262d
              const SizedBox(height: 16),

              // Debug Info (conditionally shown)
              _buildDebugInfo(),

              // Tasks Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: coffeeShadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.task_alt, color: caramelBrown, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Your Tasks",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: espresso,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTasksList()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [coffeeBrown, caramelBrown],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: coffeeBrown.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

// Link for history notification: https://claude.ai/chat/4e90f8c9-11de-4c98-a94e-1c327124d84e
class CoffeeBeanPainter extends CustomPainter {
  final Color beanColor;

  CoffeeBeanPainter({required this.beanColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = beanColor.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    // Draw coffee beans scattered across the card
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (i * size.width / 8) + (j % 2 == 0 ? 0 : size.width / 16);
        final y = (j * size.height / 4) + 10;

        // Draw coffee bean shape (oval with center line)
        final beanRect = Rect.fromCenter(
          center: Offset(x, y),
          width: 12,
          height: 8,
        );
        canvas.drawOval(beanRect, paint);

        // Draw center line of coffee bean
        final linePaint =
            Paint()
              ..color = beanColor.withOpacity(0.15)
              ..strokeWidth = 1;
        canvas.drawLine(Offset(x - 4, y), Offset(x + 4, y), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

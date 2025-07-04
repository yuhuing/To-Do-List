import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/AppDrawer.dart';
import '../screens/TaskModel.dart';
import '../screens/TaskProvider.dart';

class LongTermTask extends StatefulWidget {
  const LongTermTask({super.key});

  @override
  State<LongTermTask> createState() => _LongTermTaskState();
}

class _LongTermTaskState extends State<LongTermTask> {
  // Rich coffee color palette
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color coffeeShadow = Color(0x1A2C1810);

  void _toggleDone(Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleTaskDoneWithConfirmation(context, task);
  }

  Future<DateTime?> _pickDate(DateTime? currentDate) async {
    final now = DateTime.now();
    return await showDatePicker(
      context: context,
      initialDate: currentDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: coffeeBrown,
              onPrimary: Colors.white,
              surface: creamWhite,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Priority _getPriorityFromDays(int daysDiff) {
    if (daysDiff <= 3) return Priority.high;
    if (daysDiff <= 7) return Priority.medium;
    return Priority.low;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.red[700],
        // behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // margin: EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Widget _buildTaskDialog({
    required TextEditingController titleController,
    required TextEditingController detailsController,
    required DateTime? selectedDate,
    required Priority? selectedPriority,
    required Function(DateTime?) onDateChanged,
    required Function(Priority?) onPriorityChanged,
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
              0.8, // Limit height to 80% of screen
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
            // Wrap content in SingleChildScrollView ***
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
                      saveButtonText == "Update" ? "Edit Task" : "New Task",
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

                SizedBox(height: 20),

                // Date and Priority row
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await _pickDate(selectedDate);
                              if (picked != null) onDateChanged(picked);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: caramelBrown,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedDate != null
                                          ? DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(selectedDate)
                                          : "Pick Date",
                                      style: TextStyle(
                                        color:
                                            selectedDate != null
                                                ? espresso
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

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
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<Priority>(
                        value: selectedPriority,
                        hint: Text(
                          "Priority",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down, color: caramelBrown),
                        items:
                            Priority.values.map((p) {
                              Color priorityColor =
                                  p == Priority.high
                                      ? Color(0xFFE53E3E)
                                      : p == Priority.medium
                                      ? Color(0xFFEA580C)
                                      : Color(0xFF10B981);
                              return DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: priorityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      p.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: onPriorityChanged,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
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

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final detailsController = TextEditingController(text: task.details);
    DateTime? selectedDate = task.dueDate;
    Priority? selectedPriority = task.priority;
    bool isPriorityManual = task.isPriorityManual;
    bool userSetPriorityManually = isPriorityManual;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              void updateTask() {
                if (titleController.text.trim().isEmpty) {
                  _showValidationError("Task title cannot be empty.");
                  return;
                }

                final taskProvider = Provider.of<TaskProvider>(
                  context,
                  listen: false,
                );
                taskProvider.updateTask(
                  task,
                  title: titleController.text.trim(),
                  details: detailsController.text.trim(),
                  dueDate:
                      selectedDate ??
                      DateTime.now().add(const Duration(days: 1)),
                  priority: selectedPriority ?? Priority.medium,
                  isPriorityManual: isPriorityManual,
                );
                Navigator.of(context).pop();
              }

              return _buildTaskDialog(
                titleController: titleController,
                detailsController: detailsController,
                selectedDate: selectedDate,
                selectedPriority: selectedPriority,
                onDateChanged:
                    (date) => setState(() {
                      selectedDate = date;
                      if (!userSetPriorityManually && date != null) {
                        final today = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        );
                        selectedPriority = _getPriorityFromDays(
                          date.difference(today).inDays,
                        );
                        isPriorityManual = false;
                      }
                    }),
                onPriorityChanged:
                    (priority) => setState(() {
                      selectedPriority = priority;
                      userSetPriorityManually = true;
                      isPriorityManual = true;
                    }),
                onSave: updateTask,
                saveButtonText: "Update",
              );
            },
          ),
    );
  }

  void _confirmDeleteTask(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 370, minWidth: 370),
              child: AlertDialog(
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
                    onPressed: () {
                      Navigator.pop(context);
                      Provider.of<TaskProvider>(
                        context,
                        listen: false,
                      ).removeTask(task);
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

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: coffeeShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: task.isDone ? null : () => _showEditTaskDialog(task),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Priority indicator
                // Container(
                //   width: 4,
                //   height: 48,
                //   decoration: BoxDecoration(
                //     color: task.priority == Priority.high ? Colors.red[600] :
                //            task.priority == Priority.medium ? Colors.orange[600] :
                //            Colors.green[600],
                //     borderRadius: BorderRadius.circular(2),
                //   ),
                // ),
                SizedBox(width: 12),

                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? Colors.grey[500] : espresso,
                        ),
                      ),
                      if (task.details.isNotEmpty) ...[
                        SizedBox(height: 3),
                        Text(
                          task.details,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2, // Add this to limit text lines
                          overflow:
                              TextOverflow
                                  .ellipsis, // Add this for text overflow
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: caramelBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: caramelBrown,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Due ${DateFormat('MMM dd').format(task.dueDate!)}',
                                style: TextStyle(
                                  color: caramelBrown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
          ),
        ),
      ),
    );
  }

  Widget _buildZone(
    String title,
    Color color,
    Priority priority,
    IconData icon,
  ) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final taskList = taskProvider.getTasksByPriority(priority);

        return GestureDetector(
          onTap: () => _navigateToExpandedView(title, priority, color, icon),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Enhanced header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${taskList.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Task list
                Expanded(
                  child:
                      taskList.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "No ${title.toLowerCase()} tasks",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: taskList.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildTaskCard(taskList[index]),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToExpandedView(
    String title,
    Priority priority,
    Color color,
    IconData icon,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExpandedTaskView(
              title: title,
              priority: priority,
              color: color,
              icon: icon,
              onEditTask: _showEditTaskDialog,
              onDeleteTask: _confirmDeleteTask,
              onToggleDone: _toggleDone,
            ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));
    Priority? selectedPriority;
    bool userSetPriorityManually = false;
    bool isPriorityManual = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              void saveTask() {
                if (titleController.text.trim().isEmpty) {
                  _showValidationError("Task title cannot be empty.");
                  return;
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                DateTime finalDate =
                    selectedDate ?? today.add(const Duration(days: 1));
                Priority finalPriority =
                    selectedPriority ??
                    _getPriorityFromDays(finalDate.difference(today).inDays);

                final newTask = Task(
                  title: titleController.text.trim(),
                  details: detailsController.text.trim(),
                  dueDate: finalDate,
                  priority: finalPriority,
                  isPriorityManual: isPriorityManual,
                );

                Provider.of<TaskProvider>(
                  context,
                  listen: false,
                ).addTask(newTask);
                Navigator.of(context).pop();
              }

              return _buildTaskDialog(
                titleController: titleController,
                detailsController: detailsController,
                selectedDate: selectedDate,
                selectedPriority: selectedPriority,
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                    if (!userSetPriorityManually && date != null) {
                      final today = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      );
                      selectedPriority = _getPriorityFromDays(
                        date.difference(today).inDays,
                      );
                      isPriorityManual = false;
                    }
                  });
                },
                onPriorityChanged: (priority) {
                  setState(() {
                    selectedPriority = priority;
                    userSetPriorityManually = true;
                    isPriorityManual = true;
                  });
                },
                onSave: saveTask,
                saveButtonText: "Add Task",
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: creamWhite,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.coffee, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Long-Term Tasks",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: espresso,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [espresso, coffeeBrown],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _buildZone(
                "Urgent",
                Colors.red[800]!,
                Priority.high,
                Icons.priority_high,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildZone(
                "Medium",
                Colors.orange[600]!,
                Priority.medium,
                Icons.schedule,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildZone(
                "Low Priority",
                Colors.green[600]!,
                Priority.low,
                Icons.low_priority,
              ),
            ),
          ],
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

class ExpandedTaskView extends StatelessWidget {
  final String title;
  final Priority priority;
  final Color color;
  final IconData icon;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;
  final Function(Task) onToggleDone;

  const ExpandedTaskView({
    Key? key,
    required this.title,
    required this.priority,
    required this.color,
    required this.icon,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onToggleDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LongTermTaskState.creamWhite,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              "$title Tasks",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final taskList = taskProvider.getTasksByPriority(priority);

          if (taskList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    "No ${title.toLowerCase()} tasks",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskList.length,
            itemBuilder:
                (context, index) => _buildExpandedTaskCard(taskList[index]),
          );
        },
      ),
    );
  }

  Widget _buildExpandedTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _LongTermTaskState.coffeeShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
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
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      color:
                          task.isDone
                              ? Colors.grey[500]
                              : _LongTermTaskState.espresso,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: task.isDone,
                    onChanged: (_) => onToggleDone(task),
                    activeColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            if (task.details.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                task.details,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
            if (task.dueDate != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5A2B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: Color(0xFF8B5A2B)),
                    SizedBox(width: 6),
                    Text(
                      'Due ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                      style: TextStyle(
                        color: Color(0xFF8B5A2B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onEditTask(task),
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text("Edit"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF8B5A2B),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onDeleteTask(task),
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text("Delete"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

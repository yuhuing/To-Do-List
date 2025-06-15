import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'TaskModel.dart';
import 'TaskProvider.dart';
import '../widgets/AppDrawer.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Task> historyTasks = [];
  bool isLoading = true;
  String errorMessage = '';

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
    _loadHistoryTasks();
  }

  Future<void> _loadHistoryTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final tasks = await taskProvider.getHistoryTasks();

      setState(() {
        historyTasks = tasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading history: $e';
        isLoading = false;
      });
    }
  }

  // Delete task from history (removes from UI, preserves in database)
  void _deleteTaskFromHistory(Task task) {
    if (task.firestoreId == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    // Mark task as deleted in TaskProvider
    taskProvider.markHistoryTaskAsDeleted(task.firestoreId!);

    // Update local state
    setState(() {
      historyTasks.remove(task);
    });

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task removed from history view'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            final taskProvider = Provider.of<TaskProvider>(
              context,
              listen: false,
            );
            // Unmark task as deleted in TaskProvider
            taskProvider.unmarkHistoryTaskAsDeleted(task.firestoreId!);

            // Update local state
            setState(() {
              historyTasks.add(task);
              // Sort tasks by updated date (most recent first)
              historyTasks.sort(
                (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
                  a.updatedAt ?? DateTime.now(),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  // Update the _toggleTaskCompletion method to use completeLate
  Future<void> _toggleTaskCompletion(Task task) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      await taskProvider.toggleTaskCompleteLate(task);

      // Update local state
      if (mounted) {
        setState(() {
          final index = historyTasks.indexOf(task);
          if (index != -1) {
            // Create updated task with toggled completeLate status
            final updatedTask = task.copyWith(completeLate: !task.completeLate);
            historyTasks[index] = updatedTask;
          }
        });
      }
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

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: coffeeShadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: coffeeBrown.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: espresso,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Only show mark as complete option if not already completed manually
                  if (!task.completeLate) ...[
                    _buildOptionTile(
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                      title: 'Mark as Complete',
                      subtitle: 'Complete this overdue task',
                      onTap: () {
                        Navigator.pop(context);
                        _toggleTaskCompletion(task);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildOptionTile(
                    icon: Icons.delete_outline,
                    iconColor: Colors.red[600]!,
                    title: 'Delete from History',
                    subtitle: 'Remove from history view',
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(task);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: milkFoam,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: coffeeBrown.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: espresso),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: coffeeBrown, fontSize: 13),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
              'Remove "${task.title}" from history?',
              style: TextStyle(color: coffeeBrown, fontWeight: FontWeight.w500),
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
                  _deleteTaskFromHistory(task);
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
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
              "Task History",
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
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadHistoryTasks,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
                    ),
                  )
                  : errorMessage.isNotEmpty
                  ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: coffeeBrown.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: coffeeBrown, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadHistoryTasks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: caramelBrown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  )
                  : historyTasks.isEmpty
                  ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: caramelBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.history,
                              size: 64,
                              color: caramelBrown,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No History Yet",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: espresso,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Incomplete tasks will appear here after midnight.",
                            style: TextStyle(fontSize: 14, color: coffeeBrown),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadHistoryTasks,
                    color: caramelBrown,
                    child: ListView.builder(
                      itemCount: historyTasks.length,
                      itemBuilder: (context, index) {
                        final task = historyTasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration:
                                    task.completeLate
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                fontSize: 18,
                                color: espresso,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.details.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    task.details,
                                    style: TextStyle(
                                      color: coffeeBrown,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: task.priorityColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: task.priorityColor.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        task.priorityDisplayName,
                                        style: TextStyle(
                                          color: task.priorityColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Due: ${_formatDate(task.dueDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: coffeeBrown,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Toggle completion status
                                IconButton(
                                  onPressed: () => _toggleTaskCompletion(task),
                                  icon: Icon(
                                    task.completeLate
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        task.completeLate
                                            ? Colors.green
                                            : coffeeBrown,
                                    size: 24,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed:
                                      () => _showDeleteConfirmation(task),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }
}

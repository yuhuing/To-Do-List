import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/TaskModel.dart';

class TaskProvider with ChangeNotifier {
  static const Color espresso = Color(0xFF2C1810); // Dark brown - main text
  static const Color coffeeBrown = Color(
    0xFF4A2C2A,
  ); // Medium dark brown - secondary text
  static const Color caramelBrown = Color(
    0xFF8B5A2B,
  ); // Medium brown - icons/accents
  static const Color lightCoffee = Color(
    0xFFB8860B,
  ); // Golden brown - highlights
  static const Color creamWhite = Color(
    0xFFFAF7F2,
  ); // Off-white cream - backgrounds
  static const Color milkFoam = Color(
    0xFFF5F2ED,
  ); // Light cream - gradient backgrounds
  static const Color cardBg = Color(
    0xFFFFFFFF,
  ); // Pure white - card backgrounds
  static const Color coffeeShadow = Color(
    0x1A2C1810,
  ); // Transparent espresso - shadows (10% opacity)

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<DateTime, List<Task>> _tasks = {};
  bool _isLoading = false;
  // Add a Set to track deleted history task IDs
  final Set<String> _deletedHistoryTaskIds = {};

  bool get isLoading => _isLoading;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get reference to user's tasks collection(create task subcollection)
  CollectionReference? get _userTasksCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('tasks');
  }

  // Expose userTasksCollection for direct StreamBuilder usage in UI
  CollectionReference? get userTasksCollection => _userTasksCollection;

  // Expose userHistoryCollection for direct usage
  CollectionReference? get userHistoryCollection => _userHistoryCollection;

  // 统一的马来西亚时间获取
  DateTime _getMalaysiaTime() {
    // return DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateTime.now();
  }

  // 统一的日期键值生成
  DateTime _getMalaysiaDateKey(DateTime date) {
    // final malaysiaTime = date.toUtc().add(const Duration(hours: 8));
    final result = DateTime(date.year, date.month, date.day);
    print('Converting date: $date -> Malaysia time: $date -> Key: $result');
    return result;
  }

  // 🔧 FIXED: Helper method to create date-only DateTime for due dates
  DateTime _createMalaysiaDateOnly(DateTime date) {
    // final malaysiaTime = date.toUtc().add(const Duration(hours: 8));
    // Return date at midnight Malaysia time
    return DateTime(date.year, date.month, date.day);
  }

  /// Initialize and load tasks from Firestore
  Future<void> initializeTasks() async {
    if (_currentUserId == null) return;

    if (_isLoading) return; // Prevent duplicate initialization

    _isLoading = true;
    // 使用 addPostFrameCallback 确保在构建完成后再通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      await _loadTasksFromFirestore();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      // 使用 addPostFrameCallback 确保在构建完成后再通知
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Load all tasks from Firestore
  Future<void> _loadTasksFromFirestore() async {
    if (_userTasksCollection == null) return;

    try {
      // 1. Load current tasks from main collection
      final querySnapshot = await _userTasksCollection!.get();
      _tasks.clear();

      for (var doc in querySnapshot.docs) {
        final taskData = doc.data() as Map<String, dynamic>;
        final task = Task.fromFirestore(doc.id, taskData);

        if (task.dueDate != null) {
          final key = _getMalaysiaDateKey(task.dueDate!);
          _tasks.putIfAbsent(key, () => []).add(task);
          print(
            'Loaded task: ${task.title}, dueDate: ${task.dueDate}, key: $key',
          ); // debug
        }
      }
      // 2. ALSO load tasks from history collection (if they exist)
      if (_userHistoryCollection != null) {
        try {
          final historySnapshot = await _userHistoryCollection!.get();
          print(
            '📊 Loaded ${historySnapshot.docs.length} tasks from history collection',
          );

          for (var doc in historySnapshot.docs) {
            final taskData = doc.data() as Map<String, dynamic>;
            final task = Task.fromFirestore(doc.id, taskData);

            if (task.dueDate != null) {
              final key = _getMalaysiaDateKey(task.dueDate!);
              _tasks.putIfAbsent(key, () => []).add(task);
              print(
                '✅ Loaded history task: ${task.title}, dueDate: ${task.dueDate}, key: $key',
              );
            }
          }
        } catch (e) {
          print(
            '⚠️ Could not load history tasks (collection might not exist): $e',
          );
        }
      }

      print(
        '🎯 Total tasks loaded: ${_tasks.values.expand((list) => list).length}',
      );
    } catch (e) {
      print('Error loading tasks from Firestore: $e');
      rethrow;
    }
  }

  /// Adds a task to Firestore and local storage
  Future<void> addTask(Task task) async {
    if (_userTasksCollection == null) return;

    try {
      // Then add to local storage with the correct date key
      if (task.dueDate != null) {
        task.dueDate = _createMalaysiaDateOnly(task.dueDate!);
      }

      print('Adding task: ${task.title}, dueDate: ${task.dueDate}'); // debug

      // Add to Firestore
      final docRef = await _userTasksCollection!.add(task.toFirestore());

      // Update task with Firestore ID
      task.firestoreId = docRef.id;

      // Add to local storage with the correct date key
      if (task.dueDate != null) {
        final key = _getMalaysiaDateKey(task.dueDate!);
        _tasks.putIfAbsent(key, () => []).add(task);
        print(
          'Task added to local storage with key: $key, tasks for this date: ${_tasks[key]?.length}',
        ); // debug
      }

      // Update user stats
      await _updateUserStats();

      notifyListeners();
      print('TaskProvider notified listeners after adding task');
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  List<Task> getTasksFor(DateTime date) {
    final key = _getMalaysiaDateKey(date);
    final tasks = _tasks[key] ?? [];
    print(
      'Getting tasks for date: $date, key: $key, found: ${tasks.length} tasks',
    );
    // Debug: Print all available date keys
    print('Available date keys: ${_tasks.keys.toList()}');
    // Filter out done tasks
    return tasks.where((task) => !task.isDone).toList();
  }

  /// Gets all tasks for a date, including completed ones
  List<Task> getAllTasksFor(DateTime date) {
    final key = _getMalaysiaDateKey(date);
    return _tasks[key] ?? [];
  }

  /// Gets tasks by priority (for LongTermTask screen)
  List<Task> getTasksByPriority(Priority priority) {
    final today = _getMalaysiaTime();
    final todayKey = DateTime(today.year, today.month, today.day);

    final filteredTasks = <Task>[];

    for (var entry in _tasks.entries) {
      for (var task in entry.value) {
        if (task.isDone || task.dueDate == null) continue;
        final dueKey = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (dueKey.isAtSameMomentAs(todayKey)) continue; // Exclude today

        if (task.isPriorityManual) {
          if (task.priority == priority) {
            filteredTasks.add(task);
          }
        } else {
          final days = dueKey.difference(todayKey).inDays;
          if (priority == Priority.high && days >= 1 && days <= 3) {
            filteredTasks.add(task);
          } else if (priority == Priority.medium && days >= 4 && days <= 7) {
            filteredTasks.add(task);
          } else if (priority == Priority.low && days > 7) {
            filteredTasks.add(task);
          }
        }
      }
    }

    filteredTasks.sort((a, b) {
      final dateA = a.dueDate ?? DateTime.now();
      final dateB = b.dueDate ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return filteredTasks;
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    // Normalize both dates to ensure they're in the same format
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    final isSame =
        d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    print('Is same day? $isSame');
    return isSame;
  }

  /// Gets overdue tasks
  List<Task> get overdueTasks {
    final now = _getMalaysiaTime();
    final todayKey = _getMalaysiaDateKey(now);
    return _tasks.entries
        .where((entry) => entry.key.isBefore(todayKey)) // Only past dates
        .expand((entry) => entry.value)
        .where((task) => !task.isDone)
        .toList();
  }

  /// Returns all tasks
  Map<DateTime, List<Task>> get allTasks => _tasks;

  /// Toggle task completion
  Future<void> toggleTaskDoneWithConfirmation(
    BuildContext context,
    Task task,
  ) async {
    if (task.isDone) {
      // If task is already done, just toggle it back without confirmation
      await toggleTaskDone(task);
      return;
    }

    // Show confirmation dialog with coffee theme
    final bool? shouldComplete = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16), // Add padding to prevent overflow
          child: Container(
            // Add constraints to prevent dialog from being too large
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
                // Wrap content in SingleChildScrollView
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with check icon and task name
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              16,
                              64,
                              17,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: const Color.fromARGB(255, 16, 64, 17),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: espresso,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Clear deletion warning notification
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: caramelBrown.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: caramelBrown.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Mark as Completed?",
                            style: TextStyle(
                              color: espresso,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "This task will be permanently deleted from your list once marked as completed.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28),

                    // Action buttons - matching first dialog style exactly
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
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
                                colors: [
                                  const Color.fromARGB(255, 14, 92, 18),
                                  const Color.fromARGB(255, 28, 123, 33),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(true),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      "Mark as Done",
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
      },
    );

    // If user confirmed, proceed with marking task as done
    if (shouldComplete == true) {
      await toggleTaskDone(task);

      // Optional: Show a success message with coffee theme
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Task "${task.title}" completed!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        );
      }
    }
  }

  /// Toggle task completion (internal method - now private)
  Future<void> toggleTaskDone(Task task) async {
    if (_userTasksCollection == null || task.firestoreId == null) return;

    try {
      // Update in Firestore
      await _userTasksCollection!.doc(task.firestoreId).update({
        'isDone': !task.isDone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update locally
      task.isDone = !task.isDone;

      // Update user stats
      await _updateUserStats();

      notifyListeners();
    } catch (e) {
      print('Error toggling task: $e');
      rethrow;
    }
  }

  /// Remove a task
  Future<void> removeTask(Task task) async {
    if (_userTasksCollection == null || task.firestoreId == null) {
      throw Exception(
        'Cannot delete task: User not authenticated or task ID missing',
      );
    }

    try {
      print(
        'Attempting to delete task: ${task.title} with ID: ${task.firestoreId}',
      );
      // Remove from Firestore
      await _userTasksCollection!.doc(task.firestoreId).delete();
      print('Task deleted from Firestore successfully');

      // Remove from local storage
      bool taskRemoved = false;
      for (var entry in _tasks.entries) {
        final taskList = entry.value;
        if (taskList.remove(task)) {
          taskRemoved = true;
          print('Task removed from local storage for date: ${entry.key}');

          // Clean up empty date entries
          if (taskList.isEmpty) {
            _tasks.remove(entry.key);
            print('Removed empty date entry: ${entry.key}');
          }
          break;
        }
      }

      if (!taskRemoved) {
        print('Warning: Task was not found in local storage');
      }

      // Update user stats
      await _updateUserStats();

      notifyListeners();
    } catch (e) {
      print('Error removing task: $e');
      rethrow;
    }
  }

  /// Update a task
  Future<void> updateTask(
    Task task, {
    String? title,
    String? details,
    DateTime? dueDate,
    Priority? priority,
    bool? isPriorityManual,
  }) async {
    if (_userTasksCollection == null || task.firestoreId == null) return;

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) {
        task.title = title;
        updates['title'] = title;
      }
      if (details != null) {
        task.details = details;
        updates['details'] = details;
      }
      if (dueDate != null) {
        // debug
        final fixedDueDate = _createMalaysiaDateOnly(dueDate);
        task.dueDate = fixedDueDate;
        updates['dueDate'] = Timestamp.fromDate(fixedDueDate);
      }
      if (priority != null) {
        task.priority = priority;
        updates['priority'] = priority.toString().split('.').last;
      }
      if (isPriorityManual != null) {
        task.isPriorityManual = isPriorityManual;
        updates['isPriorityManual'] = isPriorityManual;
      }

      // Update in Firestore
      await _userTasksCollection!.doc(task.firestoreId).update(updates);

      // If due date changed, reorganize local storage
      if (dueDate != null) {
        // Remove from old location
        for (var taskList in _tasks.values) {
          taskList.remove(task);
        }

        // Add to new location
        final key = _getMalaysiaDateKey(dueDate);
        _tasks.putIfAbsent(key, () => []).add(task);
      }

      notifyListeners();
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  /// Update user statistics in Firestore
  Future<void> _updateUserStats() async {
    if (_currentUserId == null) return;

    try {
      final allTasksList =
          _tasks.values.expand((taskList) => taskList).toList();
      final totalTasks = allTasksList.length;
      final completedTasks = allTasksList.where((task) => task.isDone).length;
      final pendingTasks = totalTasks - completedTasks;

      await _firestore.collection('users').doc(_currentUserId).update({
        'tasksCount': totalTasks,
        'completedTasksCount': completedTasks,
        'pendingTasksCount': pendingTasks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  /// Clear all tasks (useful for logout)
  void clearTasks() {
    _tasks.clear();
    notifyListeners();
  }

  /// Get reference to user's task history collection
  CollectionReference? get _userHistoryCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('taskHistory');
  }

  // Additional methods to add to your TaskProvider class

  /// Update task in database only (without affecting local storage)
  Future<void> updateTaskInDatabase(Task task) async {
    if (_userTasksCollection == null || task.firestoreId == null) return;

    try {
      await _userTasksCollection!.doc(task.firestoreId).update({
        'isDone': task.isDone,
        'updatedAt': FieldValue.serverTimestamp(),
        'title': task.title,
        'details': task.details,
        'dueDate':
            task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
        'priority': task.priority.toString().split('.').last,
      });

      print('Task updated in database: ${task.title}');
    } catch (e) {
      print('Error updating task in database: $e');
      rethrow;
    }
  }

  /// Remove task from local storage only (UI) without affecting database
  void removeTaskFromLocalStorage(Task task) {
    try {
      // Remove from local storage map
      for (var entry in _tasks.entries) {
        final taskList = entry.value;
        if (taskList.contains(task)) {
          taskList.remove(task);
          print('Task removed from local storage: ${task.title}');

          // Clean up empty date entries
          if (taskList.isEmpty) {
            _tasks.remove(entry.key);
          }
          break;
        }
      }

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      print('Error removing task from local storage: $e');
    }
  }

  /// Get completed tasks from database (for analytics or recovery purposes)
  Future<List<Task>> getCompletedTasksFromDatabase({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userTasksCollection == null) return [];

    try {
      Query query = _userTasksCollection!.where('isDone', isEqualTo: true);

      // Add date filters if provided
      if (startDate != null) {
        query = query.where(
          'dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'dueDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot =
          await query.orderBy('updatedAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final taskData = doc.data() as Map<String, dynamic>;
        return Task.fromFirestore(doc.id, taskData);
      }).toList();
    } catch (e) {
      print('Error getting completed tasks from database: $e');
      return [];
    }
  }

  /// Get count of completed tasks for statistics
  Future<int> getCompletedTasksCount({DateTime? forDate}) async {
    if (_userTasksCollection == null) return 0;

    try {
      Query query = _userTasksCollection!.where('isDone', isEqualTo: true);

      if (forDate != null) {
        final startOfDay = DateTime(forDate.year, forDate.month, forDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        query = query
            .where(
              'dueDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay));
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting completed tasks count: $e');
      return 0;
    }
  }

  /// Add task to history collection
  Future<void> addTaskToHistory(Task task) async {
    if (_userHistoryCollection == null) return;

    try {
      await _userHistoryCollection!.add(task.toFirestore());
      print('Task added to history: ${task.title}');
    } catch (e) {
      print('Error adding task to history: $e');
      rethrow;
    }
  }

  /// Get all history tasks
  Future<List<Task>> getHistoryTasks() async {
    if (_userHistoryCollection == null) return [];

    try {
      final querySnapshot =
          await _userHistoryCollection!
              .orderBy('updatedAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) {
            final taskData = doc.data() as Map<String, dynamic>;
            return Task.fromFirestore(doc.id, taskData);
          })
          .where((task) => !_deletedHistoryTaskIds.contains(task.firestoreId))
          .toList();
    } catch (e) {
      print('Error loading history tasks: $e');
      rethrow;
    }
  }

  /// Delete a task from history
  Future<void> deleteHistoryTask(Task task) async {
    if (_userHistoryCollection == null || task.firestoreId == null) return;

    try {
      await _userHistoryCollection!.doc(task.firestoreId).delete();
      print('Task deleted from history: ${task.title}');
    } catch (e) {
      print('Error deleting history task: $e');
      rethrow;
    }
  }

  /// Clear all history tasks
  Future<void> clearHistory() async {
    if (_userHistoryCollection == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _userHistoryCollection!.get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All history tasks cleared');
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }

  /// Mark task as complete late (for History section only)
  /// This sets completeLate to true while keeping isDone as false
  /// Used to identify tasks that were completed after the due date
  Future<void> markTaskAsCompleteLate(Task task) async {
    if (_userHistoryCollection == null || task.firestoreId == null) return;

    try {
      // Update in Firestore history collection
      await _userHistoryCollection!.doc(task.firestoreId).update({
        'completeLate': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update locally
      task.completeLate = true;

      print('Task marked as complete late: ${task.title}');
      notifyListeners();
    } catch (e) {
      print('Error marking task as complete late: $e');
      rethrow;
    }
  }

  /// Toggle task completeLate status
  Future<void> toggleTaskCompleteLate(Task task) async {
    try {
      final updatedTask = task.copyWith(completeLate: !task.completeLate);
      await _userHistoryCollection?.doc(task.firestoreId).update({
        'completeLate': updatedTask.completeLate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      if (task.dueDate != null) {
        final key = _getMalaysiaDateKey(task.dueDate!);
        final tasks = _tasks[key] ?? [];
        final index = tasks.indexOf(task);
        if (index != -1) {
          tasks[index] = updatedTask;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error toggling task completeLate status: $e');
      rethrow;
    }
  }

  /// Get total completed tasks across all dates
  Future<int> getTotalCompletedTasks() async {
    int completedCount =
        _tasks.values
            .expand((tasks) => tasks)
            .where((task) => task.isDone)
            .length;

    // Add count from history tasks that are marked as completeLate
    if (_userHistoryCollection != null) {
      try {
        final historySnapshot =
            await _userHistoryCollection!
                .where('completeLate', isEqualTo: true)
                .get();
        completedCount += historySnapshot.docs.length;
      } catch (e) {
        print('Error getting completed history tasks: $e');
      }
    }

    return completedCount;
  }

  /// Get total pending tasks across all dates
  int getTotalPendingTasks() {
    return _tasks.values
        .expand((tasks) => tasks)
        .where((task) => !task.isDone)
        .length;
  }

  /// Add a test history task manually (for testing purposes)
  Future<void> addTestHistoryTask({
    required String title,
    required DateTime dueDate,
    String details = '',
    Priority priority = Priority.medium,
    bool isPriorityManual = false,
  }) async {
    if (_userHistoryCollection == null) return;

    try {
      final task = Task(
        title: title,
        details: details,
        dueDate: dueDate,
        priority: priority,
        isPriorityManual: isPriorityManual,
        isDone: false,
        completeLate: false,
        updatedAt: DateTime.now(),
      );

      await _userHistoryCollection!.add(task.toFirestore());
      print('Test history task added: $title');
    } catch (e) {
      print('Error adding test history task: $e');
      rethrow;
    }
  }

  // Add getter for deleted history task IDs
  Set<String> get deletedHistoryTaskIds => _deletedHistoryTaskIds;

  // Add method to mark a history task as deleted
  void markHistoryTaskAsDeleted(String taskId) {
    _deletedHistoryTaskIds.add(taskId);
    notifyListeners();
  }

  // Add method to unmark a history task as deleted
  void unmarkHistoryTaskAsDeleted(String taskId) {
    _deletedHistoryTaskIds.remove(taskId);
    notifyListeners();
  }

  /// Get count of non-deleted history tasks
  Future<int> getNonDeletedHistoryTasksCount() async {
    if (_userHistoryCollection == null) return 0;

    try {
      final querySnapshot = await _userHistoryCollection!.get();
      return querySnapshot.docs
          .where((doc) => !_deletedHistoryTaskIds.contains(doc.id))
          .length;
    } catch (e) {
      print('Error getting non-deleted history tasks count: $e');
      return 0;
    }
  }
}

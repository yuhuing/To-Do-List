// Improved MidnightTaskService.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'TaskProvider.dart';
import 'TaskModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MidnightTaskService {
  static Timer? _midnightTimer;
  static bool _midnightHandled = false;
  static StreamSubscription? _taskSubscription;
  static BuildContext? _context;

  // Malaysia Time
  // static DateTime _getMalaysiaTime() {
  //   return DateTime.now().toUtc().add(const Duration(hours: 8));
  // }

  // static DateTime _getMalaysiaDateKey(DateTime dateTime) {
  //   final malaysiaTime = dateTime.toUtc().add(const Duration(hours: 8));
  //   return DateTime(malaysiaTime.year, malaysiaTime.month, malaysiaTime.day);
  // }

  static DateTime _getMalaysiaTime() {
    return DateTime.now();
  }

  static DateTime _getMalaysiaDateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Initialize the midnight service (如果当前时间已经过午夜，且未处理 → 执行处理)
  static Future<void> initialize(BuildContext context) async {
    try {
      _context = context;

      // Load the midnight handled status
      await _loadMidnightHandled();

      // Check if we need to handle midnight for today
      final now = _getMalaysiaTime();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      if (now.isAfter(todayMidnight) && !_midnightHandled) {
        await _handleMidnight(context);
      }

      // Schedule the next midnight check
      _scheduleMidnightCheck(context);

      // Start listening to app lifecycle changes
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
    } catch (e) {
      print('Error initializing midnight service: $e');
    }
  }

  // Enhanced scheduling with multiple fallbacks 安排定时任务
  static void _scheduleMidnightCheck(BuildContext context) {
    _midnightTimer?.cancel();

    final now = _getMalaysiaTime();

    final todayMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ); // eg: 2025, 6, 8, 0hr, 0min, 0sec, 0milisec, 0microsec
    final nextMidnight = todayMidnight.add(const Duration(days: 1));

    final diff = nextMidnight.difference(now);
    // final diff = Duration(minutes: 1); // Test: 3 minutes

    _midnightTimer = Timer(diff, () async {
      if (_context != null) {
        await _handleMidnight(_context!);
        _scheduleMidnightCheck(_context!); // Schedule next check
      }
    });
  }

  // Enhanced midnight handling with better error recovery真正执行午夜任务处理
  static Future<void> _handleMidnight(BuildContext context) async {
    if (_midnightHandled) return;

    try {
      print('Starting midnight task management...');

      // Get TaskProvider from context
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      // Ensure tasks are loaded from Firestore
      await taskProvider.initializeTasks();

      final now = _getMalaysiaTime();
      final previousDay = now.subtract(const Duration(days: 1));
      final previousDayKey = _getMalaysiaDateKey(previousDay);

      // Get all tasks for the previous day, including completed ones
      final previousDayTasks = taskProvider.getAllTasksFor(previousDayKey);
      print('Current Malaysia time: ${now.toString()}');
      print('Processing tasks for Malaysia date: ${previousDayKey.toString()}');
      print('Found ${previousDayTasks.length} tasks from the previous day');

      // Process yesterday's tasks
      int completedRemovedCount = 0;
      int incompleteMovedCount = 0;

      for (var task in previousDayTasks) {
        try {
          if (!task.isDone) {
            // Move incomplete tasks to history
            await _moveTaskToHistory(task, taskProvider);
            incompleteMovedCount++;
            print('Incomplete task moved to history: ${task.title}');
          }
          // else: do nothing, keep completed tasks for analytics/history
        } catch (e) {
          print('Error processing task ${task.title}: $e');
          // Continue with other tasks even if one fails
        }
      }

      // Update midnight handled status
      await _setMidnightHandled(true);

      print(
        'Midnight task management completed: $completedRemovedCount deleted, $incompleteMovedCount moved to history',
      );
    } catch (e) {
      print('Error handling midnight tasks: $e');
      // Don't mark as handled if there was an error
    }
  }

  // Load midnight handled status from SharedPreferences
  // _midnightHandled = true: 已经执行过午夜相关任务了，不需要重复执行
  // _midnightHandled = false: 还没执行午夜任务，需要去做一次
  static Future<void> _loadMidnightHandled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 从本地保存的数据中获取上次处理日期(找lastHandledDate)
      final lastHandledDate = prefs.getString('lastHandledDate');
      // 获取今天的日期，格式化成yyyy-MM-dd
      final nowDate = DateFormat('yyyy-MM-dd').format(_getMalaysiaTime());

      // 如果 "上次处理日期" 与 "今天的日期" 不同，则重置midnightHandled
      if (lastHandledDate != nowDate) {
        _midnightHandled = false; // 将 midnightHandled = false，准备重新执行午夜处理逻辑
        await prefs.setString(
          'lastHandledDate',
          nowDate,
        ); // 把当前日期保存到本地，作为"最后处理日期"，方便下次判断
        await prefs.setBool(
          'midnightHandled',
          false,
        ); // 把午夜任务未处理的状态保存到本地，确保状态和内存变量一致。
        print('New day detected(Malaysia time), midnight handling reset');
      } else {
        // 表示今天已经是同一天了，不需要重置。
        _midnightHandled =
            prefs.getBool('midnightHandled') ??
            false; // 读取SharedPreference里 'midnightHandled'的bool,读取到了就赋值,没读取到就set false
        print('Midnight handled status loaded: $_midnightHandled');
      }
    } catch (e) {
      print('Error loading midnight status: $e');
      _midnightHandled = false;
    }
  }

  // Set midnight handled status
  static Future<void> _setMidnightHandled(bool handled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowDate = DateFormat('yyyy-MM-dd').format(_getMalaysiaTime());

      await prefs.setBool('midnightHandled', handled);
      await prefs.setString('lastHandledDate', nowDate);
      _midnightHandled = handled;

      print('Midnight handled status set to: $handled');
    } catch (e) {
      print('Error setting midnight status: $e');
    }
  }

  // Move incomplete task to history with better error handling
  static Future<void> _moveTaskToHistory(
    Task task,
    TaskProvider taskProvider,
  ) async {
    try {
      // Create a history entry for the incomplete task
      final historyTask = task.copyWith(
        isDone: false, // Mark as incomplete in history
        updatedAt: DateTime.now(), // Update the timestamp
      );

      // Use a transaction to ensure atomicity
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // First check if task already exists in history
        final historyCollection = taskProvider.userHistoryCollection;
        if (historyCollection == null) return;

        final historyQuery =
            await historyCollection
                .where('title', isEqualTo: task.title)
                .where('dueDate', isEqualTo: Timestamp.fromDate(task.dueDate!))
                .get();

        if (historyQuery.docs.isEmpty) {
          // Add to history collection in Firebase
          final historyRef = historyCollection.doc();
          transaction.set(historyRef, historyTask.toFirestore());

          // Remove from current tasks
          if (task.firestoreId != null) {
            final taskRef = taskProvider.userTasksCollection!.doc(
              task.firestoreId,
            );
            transaction.delete(taskRef);
          }
        } else {
          print('Task already exists in history: ${task.title}');
          // If task exists in history, just remove it from current tasks
          if (task.firestoreId != null) {
            final taskRef = taskProvider.userTasksCollection!.doc(
              task.firestoreId,
            );
            transaction.delete(taskRef);
          }
        }
      });

      print('Task moved to history: ${task.title}');
    } catch (e) {
      print('Error moving task to history: $e');
      rethrow;
    }
  }

  // Check if midnight handling should occur
  static Future<bool> shouldHandleMidnight() async {
    await _loadMidnightHandled();
    // final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return now.isAfter(todayMidnight) && !_midnightHandled;
  }

  // Force check and handle if needed (call this when app resumes)
  static Future<void> checkAndHandle(BuildContext context) async {
    if (await shouldHandleMidnight()) {
      await _handleMidnight(context);
    }
  }

  // Get midnight handled status
  static bool get isMidnightHandled => _midnightHandled;

  // Get time until next midnight
  static Duration getTimeUntilMidnight() {
    final now = _getMalaysiaTime();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final nextMidnight = todayMidnight.add(const Duration(days: 1));
    return nextMidnight.difference(now);
  }

  // Reset midnight handled status (useful for testing)
  static Future<void> resetMidnightStatus() async {
    await _setMidnightHandled(false);
    print('Midnight status reset for testing');
  }

  // ADDED: Method for manual testing of midnight logic
  static Future<void> testMidnightHandling(BuildContext context) async {
    print('=== TESTING MIDNIGHT HANDLING ===');
    final now = _getMalaysiaTime();
    print('Current Malaysia time: $now');

    // Simulate what would happen at midnight
    final previousDay = now.subtract(const Duration(days: 1));
    final previousDayKey = _getMalaysiaDateKey(previousDay);

    print('Would process tasks from: ${previousDayKey.toString()}');

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasksToProcess = taskProvider.getAllTasksFor(previousDayKey);

    print('Found ${tasksToProcess.length} tasks that would be processed:');
    for (var task in tasksToProcess) {
      print('  - ${task.title} (Due: ${task.dueDate}, Done: ${task.isDone})');
    }
    print('=== END TEST ===');
  }

  // Dispose method to clean up resources
  static void dispose() {
    _midnightTimer?.cancel();
    _taskSubscription?.cancel();
    _context = null;
  }
}

// App lifecycle observer to handle app resume
// 应用程序从后台（暂停状态）恢复到前台（resume）时，它会检查是否需要执行午夜任务处理
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 状态: resumed(app从后台回来) && MidnightTaskService 有context(值)
    if (state == AppLifecycleState.resumed &&
        MidnightTaskService._context != null) {
      // Check if midnight handling is needed when app resumes
      MidnightTaskService.checkAndHandle(MidnightTaskService._context!);
    }
  }
}

// for UI deletion: https://claude.ai/chat/33fb74a4-989d-427b-a176-44db20f3aa7f

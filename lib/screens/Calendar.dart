import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/AppDrawer.dart';
import '../screens/TaskModel.dart';
import '../screens/TaskProvider.dart'; // 👈 import your provider

// ======= COLOR CONSTANTS (MOVED OUTSIDE CLASS) =======
// Rich coffee color palette
const Color espresso = Color(0xFF2C1810);
const Color coffeeBrown = Color(0xFF4A2C2A);
const Color caramelBrown = Color(0xFF8B5A2B);
const Color creamWhite = Color(0xFFFAF7F2);
const Color milkFoam = Color(0xFFF5F2ED);
const Color cardBg = Color(0xFFFFFFFF);
const Color coffeeShadow = Color(0x1A2C1810);

void main() {
  runApp(
    ChangeNotifierProvider(create: (context) => TaskProvider(), child: MyApp()),
  );
}

// Main App Widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(primarySwatch: Colors.brown),
      debugShowCheckedModeBanner: false,
      home: CalendarPage(), // ✅ <- Your calendar screen here
    );
  }
}

// CalenderPage (Stateful)
// because need to track selected date, completed days and focused month
class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

// State Class for CalendarPage
class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now(); // ✅ Always shows current month/day
  DateTime? _selectedDay; // the day user taps on
  // **
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize tasks from database when calendar loads ***
    _initializeTasksFromDatabase();
  }

  // Initialize tasks from Firestore ***
  Future<void> _initializeTasksFromDatabase() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.initializeTasks();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing tasks: $e');
      // Show error message to user if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks from database'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to check if a day should have a star sticker
  bool _shouldShowStar(DateTime date) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasksForDate = taskProvider.getAllTasksFor(date);

    // Condition 3: No tasks at all = no sticker
    if (tasksForDate.isEmpty) {
      return false;
    }

    // Get tasks that were completed on time (isDone = true)
    final completedTasks = tasksForDate.where((task) => task.isDone).toList();
    // Get tasks that were completed late (completeManually = true)
    final lateCompletedTasks =
        tasksForDate.where((task) => task.completeLate).toList();
    // Get pending tasks
    final pendingTasks =
        tasksForDate
            .where((task) => !task.isDone && !task.completeLate)
            .toList();

    // Condition 1: Has pending tasks = no sticker
    if (pendingTasks.isNotEmpty) {
      return false;
    }

    // Condition 2: No pending tasks AND has completed tasks (but not late completed) = show star
    if (pendingTasks.isEmpty &&
        completedTasks.isNotEmpty &&
        lateCompletedTasks.isEmpty) {
      return true;
    }

    return false;
  }

  // Build method (UI layout)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              "Task Calendar",
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
        // ***
        actions: [
          // Add refresh button to manually reload from database
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _initializeTasksFromDatabase();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tasks refreshed from database'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),

      //List Tile
      drawer: const AppDrawer(),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [creamWhite, milkFoam],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Show loading indicator while initializing ***
            if (!_isInitialized)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: coffeeShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(espresso),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Loading tasks from database...',
                      style: TextStyle(
                        color: espresso,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // ***

            // Calendar Container with coffee theme
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: coffeeShadow,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    // Show loading indicator inside calendar *** if still loading
                    if (taskProvider.isLoading && !_isInitialized) {
                      return Container(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  espresso,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading calendar data...',
                                style: TextStyle(color: espresso, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // ***
                    return TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },

                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          color: espresso,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        formatButtonVisible: false,
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: espresso,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: espresso,
                        ),
                      ),

                      // Coffee-themed calendar styling
                      calendarStyle: CalendarStyle(
                        // Today's date styling
                        todayDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [caramelBrown, coffeeBrown],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),

                        // Selected date styling
                        selectedDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [espresso, coffeeBrown],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: coffeeShadow,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),

                        // Default date styling
                        defaultTextStyle: TextStyle(color: espresso),
                        weekendTextStyle: TextStyle(color: caramelBrown),
                        outsideTextStyle: TextStyle(
                          color: Colors.grey.shade400,
                        ),

                        // Marker styling
                        markerDecoration: BoxDecoration(shape: BoxShape.circle),
                        markersMaxCount: 3,

                        // Cell decoration
                        cellMargin: EdgeInsets.all(4),
                        cellPadding: EdgeInsets.zero,
                      ),

                      // Days of week styling
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: coffeeBrown,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: caramelBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      selectedDayPredicate:
                          (day) => isSameDay(_selectedDay, day),

                      // 1. Updates _selectedday and _focusedDay
                      // 2. opens bottom sheet if tasks exist on that date
                      onDaySelected: (selected, focused) {
                        final normalized = _stripTime(selected);

                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });

                        if (taskProvider
                            .getAllTasksFor(normalized)
                            .isNotEmpty) {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(25),
                              ),
                            ),
                            builder: (context) => _buildTaskList(normalized),
                          );
                        }
                      },

                      // Calendar builders with star sticker logic
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final normalizedDate = _stripTime(date);
                          final tasksForDate = taskProvider.getAllTasksFor(
                            normalizedDate,
                          );

                          List<Widget> markers = [];

                          // Add star sticker if conditions are met
                          if (_shouldShowStar(normalizedDate)) {
                            markers.add(
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Add task priority dots (existing logic)
                          if (tasksForDate.isNotEmpty) {
                            List<Color> colors =
                                tasksForDate.map((task) {
                                  switch (task.priority) {
                                    case Priority.high:
                                      return Colors.red.shade600;
                                    case Priority.medium:
                                      return Colors
                                          .orange
                                          .shade600; // Changed from caramelBrown to orange for better visibility
                                    case Priority.low:
                                      return Colors.green.shade600;
                                    default:
                                      return Colors.grey.shade600;
                                  }
                                }).toList();

                            markers.add(
                              Positioned(
                                bottom: 2,
                                left: 0,
                                right: 0,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 2,
                                  children:
                                      colors.take(3).map((color) {
                                        return Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.3),
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            );
                          }

                          if (markers.isEmpty) return const SizedBox.shrink();

                          return Stack(
                            clipBehavior: Clip.none,
                            children: markers,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ✅ IMPROVED Task List Modal Sheet - Now Scrollable with Clear Status Icons
  Widget _buildTaskList(DateTime day) {
    final tasks = Provider.of<TaskProvider>(context).getAllTasksFor(day);
    final completedTasks = tasks.where((task) => task.isDone).length;
    final totalTasks = tasks.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.6, // Start at 60% of screen height
      minChildSize: 0.3, // Minimum 30% of screen height
      maxChildSize: 0.9, // Maximum 90% of screen height
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: coffeeShadow,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header with coffee theme (Fixed - not scrollable)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [creamWhite, milkFoam],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [espresso, coffeeBrown],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.day}/${day.month}/${day.year}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: espresso,
                          ),
                        ),
                        Text(
                          'Tasks: $completedTasks/$totalTasks completed',
                          style: TextStyle(color: coffeeBrown, fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Show star in modal if all conditions are met
                    if (_shouldShowStar(day))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade100,
                              Colors.orange.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'All Done!',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ SCROLLABLE Task List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: task.isDone ? Colors.green.shade50 : milkFoam,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              task.isDone
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: coffeeShadow,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                            color:
                                task.isDone ? Colors.green.shade700 : espresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // ✅ IMPROVED Status Indicator (Read-Only)
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                task.completeLate
                                    ? Colors.amber.shade100
                                    : task.isDone
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  task.completeLate
                                      ? Colors.amber.shade300
                                      : task.isDone
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.completeLate
                                    ? Icons.timer
                                    : task.isDone
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color:
                                    task.completeLate
                                        ? Colors.amber.shade700
                                        : task.isDone
                                        ? Colors.green.shade600
                                        : Colors.orange.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                task.completeLate
                                    ? 'Done Late'
                                    : task.isDone
                                    ? 'Done'
                                    : 'Pending',
                                style: TextStyle(
                                  color:
                                      task.completeLate
                                          ? Colors.amber.shade800
                                          : task.isDone
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        subtitle:
                            task.details.isEmpty
                                ? null
                                : Text(
                                  task.details,
                                  style: TextStyle(
                                    color:
                                        task.isDone
                                            ? Colors.green.shade600
                                            : coffeeBrown,
                                    fontSize: 13,
                                  ),
                                ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ Add bottom padding
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Navigation button widget with coffee theme
  Widget _navButton(String label) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              label == 'Page 4'
                  ? [Colors.orange, Colors.deepOrange]
                  : [espresso, coffeeBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: coffeeShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Add navigation logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'TaskModel.dart';
import '../widgets/AppDrawer.dart';
import 'TaskProvider.dart';

class PersonalProfile extends StatelessWidget {
  const PersonalProfile({super.key});

  // Color constants matching the pattern
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color coffeeShadow = Color(0x1A2C1810);

  /// Calculates the fraction of tasks done this week
  double getWeeklyCompletionRate(Map<DateTime, List<Task>> allTasks) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final weeklyTasks =
        allTasks.entries
            .where(
              (entry) =>
                  !entry.key.isBefore(
                    DateTime(
                      startOfWeek.year,
                      startOfWeek.month,
                      startOfWeek.day,
                    ),
                  ),
            )
            .expand((entry) => entry.value)
            .toList();

    if (weeklyTasks.isEmpty) return 0.0;

    final completed = weeklyTasks.where((task) => task.isDone).length;
    return completed / weeklyTasks.length;
  }

  /// Builds the data points for the 7‑day bar chart showing completed tasks count
  List<BarChartGroupData> getWeeklyBarData(TaskProvider taskProvider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Initialize a map from day index (0=Mon..6=Sun) to completed task count
    Map<int, int> dailyCompletedCount = {for (var i = 0; i < 7; i++) i: 0};

    // Get all tasks and check their completion date
    final allTasks = taskProvider.allTasks;

    for (var entry in allTasks.entries) {
      final tasks = entry.value;
      for (var task in tasks) {
        // Check if task is either done or marked as completeManually
        if ((task.isDone || task.completeLate) && task.updatedAt != null) {
          // Calculate which day of the week this task was completed
          final completionDate = task.updatedAt!;
          final daysSinceWeekStart =
              completionDate
                  .difference(
                    DateTime(
                      startOfWeek.year,
                      startOfWeek.month,
                      startOfWeek.day,
                    ),
                  )
                  .inDays;

          // If completed within this week, increment the count
          if (daysSinceWeekStart >= 0 && daysSinceWeekStart < 7) {
            dailyCompletedCount[daysSinceWeekStart] =
                dailyCompletedCount[daysSinceWeekStart]! + 1;
          }
        }
      }
    }

    // Add debug print to check counts
    print('Daily completed counts: $dailyCompletedCount');

    // Convert to BarChartGroupData
    return dailyCompletedCount.entries.map((entry) {
      final dayIndex = entry.key;
      final count = entry.value;

      return BarChartGroupData(
        x: dayIndex,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: caramelBrown,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              colors: [caramelBrown, caramelBrown.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Get the maximum count for proper scaling
  double getMaxCount(List<BarChartGroupData> barData) {
    if (barData.isEmpty) return 10;
    final maxCount = barData
        .map((group) => group.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);
    return maxCount > 0
        ? maxCount + 2
        : 10; // Add padding and ensure minimum scale
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTasks = taskProvider.getTasksFor(today);
    final allTasks = taskProvider.allTasks;

    final remaining = taskProvider.getTotalPendingTasks();
    final weeklyPercentage = (getWeeklyCompletionRate(allTasks) * 100)
        .toStringAsFixed(1);
    final barData = getWeeklyBarData(taskProvider);
    final maxCount = getMaxCount(barData);

    // Calculate total completed tasks this week
    final weeklyCompletedCount = barData.fold<int>(
      0,
      (sum, group) => sum + group.barRods.first.toY.toInt(),
    );

    return Scaffold(
      drawer: const AppDrawer(),
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
              "Personal Profile",
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Row - Profile and Stats
              Row(
                children: [
                  // Profile Avatar Section
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(16),
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
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: caramelBrown.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: caramelBrown,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Welcome Back!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: espresso,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Today's Tasks Stats
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<int>(
                            future: taskProvider.getTotalCompletedTasks(),
                            builder: (context, snapshot) {
                              final completed = snapshot.data ?? 0;
                              return _buildStatCard(
                                "Completed",
                                "$completed",
                                Colors.green,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            "Pending",
                            "$remaining",
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Combined Weekly Progress Chart and Stats
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
                      // Header with title and weekly total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Weekly Progress",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: espresso,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: caramelBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: caramelBrown.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: caramelBrown,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$weeklyCompletedCount",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: caramelBrown,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "tasks",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: coffeeBrown,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Subtitle
                      const SizedBox(height: 4),
                      Text(
                        "Tasks completed per day",
                        style: TextStyle(
                          fontSize: 14,
                          color: coffeeBrown.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bar Chart
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            maxY: maxCount,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                // tooltipBgColor: espresso.withOpacity(0.9),
                                // tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  const days = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun",
                                  ];
                                  final dayName = days[group.x.toInt()];
                                  final count = rod.toY.toInt();
                                  return BarTooltipItem(
                                    '$dayName\n$count task${count == 1 ? '' : 's'}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (
                                    double value,
                                    TitleMeta meta,
                                  ) {
                                    const days = [
                                      "Mon",
                                      "Tue",
                                      "Wed",
                                      "Thu",
                                      "Fri",
                                      "Sat",
                                      "Sun",
                                    ];
                                    final index = value.toInt();
                                    if (index >= 0 && index < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          days[index],
                                          style: TextStyle(
                                            color: coffeeBrown,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 32,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval:
                                      maxCount > 10
                                          ? (maxCount / 5).ceil().toDouble()
                                          : 2,
                                  getTitlesWidget: (
                                    double value,
                                    TitleMeta meta,
                                  ) {
                                    if (value == 0) {
                                      return Text(
                                        '0',
                                        style: TextStyle(
                                          color: coffeeBrown,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      );
                                    }
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: coffeeBrown,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                  reservedSize: 32,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            barGroups: barData,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval:
                                  maxCount > 10
                                      ? (maxCount / 5).ceil().toDouble()
                                      : 2,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Bottom encouragement text
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          weeklyCompletedCount > 0
                              ? "This week’s performance? Stronger than a double espresso!🍵"
                              : "Ready to start achieving? 💪",
                          style: TextStyle(
                            fontSize: 14,
                            color: coffeeBrown,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a stat card
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
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
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: coffeeBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

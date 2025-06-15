import 'package:flutter/material.dart';
import 'TodayTask.dart';
import 'LongTermTask.dart';
import 'Calendar.dart';
import 'GroupCollab.dart';
import 'Profile.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final VoidCallback? onFabPressed;
  final List<Widget>? actions;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    this.onFabPressed,
    this.actions,
  });

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const TodayTask(username: 'TestUser');
        break;
      case 1:
        page = const LongTerm();
        break;
      case 2:
        page = const Calendar();
        break;
      case 3:
        page = const GroupCollab();
        break;
      case 4:
        page = const Profile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.task,
      Icons.flag,
      Icons.calendar_today,
      Icons.group,
      Icons.person,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      body: body,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: const Color(0xFFEADBC8),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final tooltips = ['Today Task', 'Long-Term Task', 'Calendar', 'Group Collaboration', 'Profile'];
            return Tooltip(
              message: tooltips[index],
              child: IconButton(
                icon: Icon(
                  icons[index],
                  color: index == selectedIndex ? Colors.brown : Colors.grey,
                ),
                onPressed: () => _navigate(context, index),
              ),
            );
          }),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: onFabPressed != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FloatingActionButton(
                onPressed: onFabPressed,
                backgroundColor: const Color(0xFFB58863),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/TodayTask.dart';
import '../screens/LongTerm.dart';
import '../screens/Calendar.dart';
import '../screens/GroupCollaborationPage.dart';
import '../screens/PersonalProfile.dart';
import '../auth/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Color constants matching PersonalProfile
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color coffeeShadow = Color(0x1A2C1810);

  // Sign out function
  Future<void> _signOut(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: coffeeShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(caramelBrown),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing out...',
                    style: TextStyle(
                      color: coffeeBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close loading dialog and navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Confirmation dialog for sign out
  void _showSignOutDialog(BuildContext context) {
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
                        Icons.logout,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: espresso,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to sign out of your account?',
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
                      _signOut(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? caramelBrown.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isSelected
                ? Border.all(color: caramelBrown.withOpacity(0.3), width: 1)
                : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? caramelBrown.withOpacity(0.2)
                    : coffeeBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? caramelBrown : coffeeBrown,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? caramelBrown : espresso,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info for display
    final currentUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: cardBg,
      child: Column(
        children: [
          // Enhanced drawer header with user info
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [espresso, coffeeBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // App Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.coffee,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Title
                    const Text(
                      "Café Checklist",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentUser?.email ?? 'No user',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: Container(
              color: milkFoam,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.today,
                    title: "Today's Tasks",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TodayTask()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.flag,
                    title: "Long-Term Task",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LongTermTask()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month,
                    title: 'Calendar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => CalendarPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.group,
                    title: 'Group Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupCollaborationPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalProfile(),
                        ),
                      );
                    },
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    height: 1,
                    decoration: BoxDecoration(
                      color: coffeeBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sign out section at the bottom
          Container(
            color: milkFoam,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showSignOutDialog(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

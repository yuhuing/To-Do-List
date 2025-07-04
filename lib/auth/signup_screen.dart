import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Coffee theme colors (matching login screen)
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [creamWhite, milkFoam, creamWhite.withOpacity(0.8)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Coffee Logo and Title
                        _buildHeader(),

                        const SizedBox(height: 30),

                        // Signup Form Card
                        _buildSignupCard(),

                        const SizedBox(height: 24),

                        // Login link
                        _buildLoginLink(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Coffee cup animation container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [coffeeBrown, caramelBrown],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: coffeeShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.coffee, size: 50, color: Colors.white),
        ),

        const SizedBox(height: 24),

        // App title
        Text(
          "Join Café Checklist",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: espresso,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Start brewing your productivity",
          style: TextStyle(
            fontSize: 14,
            color: coffeeBrown.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: coffeeShadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Create Account",
            //   style: TextStyle(
            //     fontSize: 22,
            //     fontWeight: FontWeight.bold,
            //     color: espresso,
            //   ),
            // ),

            // const SizedBox(height: 8),

            // Text(
            //   "Sign up to get started",
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: coffeeBrown.withOpacity(0.7),
            //   ),
            // ),

            // const SizedBox(height: 32),

            // Email field
            _buildCustomTextField(
              controller: _email,
              label: "Email",
              hint: "Enter your email",
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 20),

            // Password field
            _buildCustomTextField(
              controller: _password,
              label: "Password",
              hint: "Create a password (min 6 characters)",
              icon: Icons.lock_outline,
              isPassword: true,
            ),

            const SizedBox(height: 20),

            // Confirm Password field
            _buildCustomTextField(
              controller: _confirmPassword,
              label: "Confirm Password",
              hint: "Confirm your password",
              icon: Icons.lock_outline,
              isPassword: true,
            ),

            const SizedBox(height: 32),

            // Signup button
            _buildSignupButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: espresso,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: milkFoam,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: coffeeShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: espresso, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: coffeeBrown.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: caramelBrown, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [coffeeBrown, caramelBrown],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: coffeeBrown.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading ? null : _signup,
            child: Center(
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: coffeeBrown.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(color: coffeeBrown, fontSize: 16),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () => goToLogin(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: caramelBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Log In",
                style: TextStyle(
                  color: caramelBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  goToLogin(BuildContext context) {
    log("Navigating to LoginScreen");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  _signup() async {
    // Prevent multiple submissions
    if (_isLoading) return;

    if (_email.text.isEmpty ||
        _password.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    if (_password.text.trim() != _confirmPassword.text.trim()) {
      _showErrorSnackBar("Passwords do not match");
      return;
    }

    if (_password.text.trim().length < 6) {
      _showErrorSnackBar("Password must be at least 6 characters");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      log("Starting signup process...");

      final user = await _auth.createUserWithEmailAndPassword(
        _email.text.trim(),
        _password.text.trim(),
      );

      if (user != null) {
        final uid = user.uid;
        log("User Created Successfully with UID: $uid");

        // Create user document with initial task statistics
        try {
          log("Creating user document in Firestore...");

          // Use batch write to ensure atomicity
          final batch = FirebaseFirestore.instance.batch();

          // Create main user document
          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(uid);
          batch.set(userDoc, {
            'email': _email.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'tasksCount': 0,
            'completedTasksCount': 0,
            'pendingTasksCount': 0,
            'profile': {
              'displayName':
                  _email.text.trim().split(
                    '@',
                  )[0], // Use email prefix as initial display name
              'photoURL': '',
            },
          });

          // Create a placeholder in tasks subcollection to ensure it exists
          final taskDoc = userDoc.collection('tasks').doc('_init');
          batch.set(taskDoc, {
            'placeholder': true,
            'createdAt': FieldValue.serverTimestamp(),
            'note': 'This document ensures the tasks subcollection exists',
          });

          // Commit the batch
          await batch.commit();

          log("User Info and Task Structure Saved to Firestore successfully");

          // Verify the data was written
          final userSnapshot = await userDoc.get();
          if (userSnapshot.exists) {
            log(
              "Verification: User document exists with data: ${userSnapshot.data()}",
            );
          } else {
            log("Warning: User document was not created successfully");
          }
        } catch (e) {
          log("Firestore write failed: $e");
          _showErrorSnackBar("Failed to save user info: ${e.toString()}");
          return;
        }

        // Show success message
        if (!mounted) return;

        _showSuccessSnackBar(
          "Account created successfully! Redirecting to login...",
        );

        // Wait 2 seconds, then navigate to login
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) {
          log("Widget no longer mounted, cannot navigate");
          return;
        }

        log("Navigating to LoginScreen");
        goToLogin(context);
      }
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException: ${e.code} - ${e.message}");
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already in use.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is not valid.";
          break;
        case 'weak-password':
          errorMessage = "The password is too weak (min 6 characters).";
          break;
        case 'operation-not-allowed':
          errorMessage = "Email/password accounts are not enabled.";
          break;
        default:
          errorMessage = e.message ?? "Signup failed. Please try again.";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      log("General error during signup: $e");
      _showErrorSnackBar("Something went wrong: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

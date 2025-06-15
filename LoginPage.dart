import 'package:flutter/material.dart';
import 'TodayTask.dart';

void main() {
  runApp(const CoffeeLoginApp());
}

class CoffeeLoginApp extends StatelessWidget {
  const CoffeeLoginApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Login',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // login method
  Future<bool> _performLogin(String username, String password) async {
    // Replace this with your actual authentication logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
  
    // Simple validation - in a real app, this would call your auth service
    return username.isNotEmpty && password == "password"; // Example simple check
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5D8),
              Color(0xFFE6D5C3),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Coffee Logo
                Image.asset(
                  'assets/coffee_logo.png',
                  height: 120,
                  width: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.coffee,
                    size: 100,
                    color: Color(0xFF6F4E37),
                  ),
                ),
                const SizedBox(height: 20),
                
                // App Name
                Text(
                  'Café Checklist',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F4E37),
                  ),
                ),
                const SizedBox(height: 40),
             
                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person, color: Color(0xFF6F4E37)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF6F4E37)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      
                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                                activeColor: Color(0xFF6F4E37),
                              ),
                              Text('Remember me',
                                  style: TextStyle(color: Color(0xFF6F4E37))),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Forgot password action
                            },
                            child: Text('Forgot password?',
                                style: TextStyle(color: Color(0xFF6F4E37))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              
                              // 1. Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6F4E37), // Coffee-themed loading
                                  ),
                                ),
                              );

                              try{
                                // 2. Simulate login process (replace with actual authentication)
                                bool loginSuccess = await _performLogin(
                                  _usernameController.text,
                                  _passwordController.text,
                                );

                                // 3. Remove loading dialog
                                Navigator.of(context).pop();

                                if (loginSuccess) {
                                  // 4. Navigate to home page
                                  // 4.1
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => TodayTask(
                                        username: _usernameController.text,
                                      ),
                                    ),
                                  );
                                } 
                                
                                else {
                                  // 4.2 Show error if login fails
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Login failed. Please check your credentials'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                            } 
                             
                          
                          catch (e) {
                            Navigator.of(context).pop(); // Ensure loading dialog is dismissed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('An error occurred: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }     
                }
  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6F4E37),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Log in',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: TextStyle(color: Color(0xFF6F4E37))),
                          TextButton(
                            onPressed: () {
                              // Navigate to sign up page
                            },
                            child: Text('Sign up',
                                style: TextStyle(
                                  color: Color(0xFF6F4E37),
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
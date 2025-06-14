import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../screens/TodayTask.dart';
import '../screens/LongTerm.dart';
import '../screens/Calendar.dart';
import '../screens/PersonalProfile.dart';
import '../screens/TaskProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyC0IvQyNjpVr1G2EAd8Ua5Z4wcrUY6DA2E",
        authDomain: "cafechecklist3.firebaseapp.com",
        databaseURL:
            "https://cafechecklist3-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "cafechecklist3",
        storageBucket: "cafechecklist3.firebasestorage.app",
        messagingSenderId: "238182649434",
        appId: "1:238182649434:web:f85346d1ed66612b7bd263",
        measurementId: "G-0HCFQ5R4YY",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TaskProvider())],
      child: MaterialApp(
        title: 'To-Do List App',
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(), // or some home screen using AppDrawer
        routes: {
          '/today': (context) => TodayTask(),
          '/longterm': (context) => LongTermTask(),
          '/calendar': (context) => CalendarPage(),
          '/profile': (context) => PersonalProfile(),
          // Add others as needed
        },
      ),
    );
  }
}

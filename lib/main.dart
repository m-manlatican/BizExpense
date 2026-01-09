import 'package:expense_tracker_3_0/firebase_options.dart';
import 'package:expense_tracker_3_0/pages/splash_screen.dart';
import 'package:expense_tracker_3_0/routes.dart'; 
import 'package:expense_tracker_3_0/app_theme.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizExpense',
      theme: AppTheme.lightTheme, 
      home: const SplashScreen(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
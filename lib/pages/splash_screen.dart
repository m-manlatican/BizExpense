import 'dart:async';
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/auth_gate.dart';
import 'package:expense_tracker_3_0/widgets/branding.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Research Standard: 2-3 seconds is ideal for branding without annoyance.
    Timer(const Duration(seconds: 3), () {
      // Navigate to AuthGate (which decides if we go to Dashboard or Login)
      // We use pushReplacement so the user can't go "back" to the loading screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Branding(
          iconSize: 80,
          fontSize: 40,
          vertical: true,
        ),
      ),
    );
  }
}
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';

class AddExpenseFab extends StatelessWidget {
  final Color backgroundColor;
  final double iconSize;
  final IconData icon;

  const AddExpenseFab({
    super.key,
    this.backgroundColor = AppColors.primary,
    this.iconSize = 24,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: backgroundColor,
      child: Icon(icon, color: Colors.white, size: iconSize),
      onPressed: () {
        // Optimized: Just navigate. The AddExpensePage handles the saving logic.
        Navigator.pushNamed(context, '/add_expense');
      },
    );
  }
}
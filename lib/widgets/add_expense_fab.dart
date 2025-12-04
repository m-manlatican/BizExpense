import 'package:expense_tracker_3_0/models/all_expense_model.dart';
// Removed unused import: add_expense_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../firestore_functions.dart';

typedef ExpenseCallback = void Function(Expense expense);

class AddExpenseFab extends StatelessWidget {
  final Color backgroundColor;
  final double iconSize;
  final IconData icon;
  final ExpenseCallback? onExpenseCreated;

  const AddExpenseFab({
    super.key,
    this.backgroundColor = const Color(0xFF00A54C),
    this.iconSize = 24,
    this.icon = Icons.add,
    this.onExpenseCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: backgroundColor,
      child: Icon(icon, color: Colors.white, size: iconSize),
      onPressed: () async {
        // Open AddExpensePage using named route
        final data = await Navigator.pushNamed(
          context, 
          '/add_expense'
        ) as Map<String, dynamic>?;

        if (data != null) {
          // Create Firestore-ready Expense object
          final expense = Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: data["title"] ?? 'Untitled',
            category: data["category"] ?? 'Other',
            amount: (data["amount"] is double)
                ? data["amount"]
                : double.tryParse('${data["amount"]}') ?? 0.0,
            dateLabel: data["dateLabel"] ?? '',
            date: Timestamp.now(), 
            notes: data["notes"] ?? '',
            iconCodePoint: Icons.receipt_long.codePoint,
            iconColorValue: const Color(0xFF30D177).value,
          );

          await addExpense(expense);

          if (onExpenseCreated != null) {
            onExpenseCreated!(expense);
          }
        }
      },
    );
  }
}
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/all_expense_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:flutter/material.dart';

class AllExpensesListView extends StatelessWidget {
  final List<Expense> expenses;
  final void Function(Expense) onEdit;
  final void Function(Expense) onDelete;
  final void Function(Expense)? onMarkAsPaid;
  final String emptyMessage;

  const AllExpensesListView({
    super.key,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
    this.onMarkAsPaid,
    this.emptyMessage = "No transactions yet", 
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }
    
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        
        return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.startToEnd, 
          background: Container(
            alignment: Alignment.centerLeft, 
            padding: const EdgeInsets.only(left: 20),
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.expense, 
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          onDismissed: (direction) {
            onDelete(expense);
          },
          child: ExpenseCard(
            expense: expense,
            onEdit: () => onEdit(expense),
            onMarkAsPaid: onMarkAsPaid != null ? () => onMarkAsPaid!(expense) : null,
          ),
        );
      },
    );
  }
}
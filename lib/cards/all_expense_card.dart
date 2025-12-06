import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;

  const ExpenseCard({super.key, required this.expense, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    Color amountColor = AppColors.textPrimary;
    String prefix = "- ";
    
    // Basic Type Logic
    if (expense.isIncome) {
      amountColor = AppColors.success; // Green
      prefix = "+ ";
    } else if (expense.isCapital) {
      amountColor = const Color(0xFF4E6AFF); // Blue
      prefix = "C ";
    }

    // 🔥 OVERRIDE IF PENDING (Unpaid)
    if (!expense.isPaid) {
      amountColor = Colors.orange; // Warning Color
      prefix = "⏳ "; // Hourglass Indicator
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: expense.iconColor.withOpacity(0.1),
                radius: 20,
                child: Icon(expense.icon, color: expense.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              
              // Title & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    // Qty details or Category
                    if (expense.quantity != null && expense.quantity! > 0)
                      Text(
                        "${expense.quantity} pcs @ ₱${(expense.amount / expense.quantity!).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      )
                    else
                      Text(expense.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              
              // Amount Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix₱${expense.amount.toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: amountColor)
                  ),
                  const SizedBox(height: 2),
                  // Status Label
                  Text(
                    expense.isPaid ? expense.dateLabel : "PENDING",
                    style: TextStyle(
                      fontSize: 12, 
                      color: expense.isPaid ? AppColors.textSecondary : Colors.orange,
                      fontWeight: expense.isPaid ? FontWeight.normal : FontWeight.bold
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Edit Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: const Text("Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
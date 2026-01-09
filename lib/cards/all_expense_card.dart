import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback? onMarkAsPaid;

  const ExpenseCard({
    super.key, 
    required this.expense, 
    required this.onEdit,
    this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    Color amountColor = AppColors.textPrimary;
    String prefix = "- ";
    
    if (expense.isIncome) {
      amountColor = AppColors.success;
      prefix = "+ ";
    } else if (expense.isCapital) {
      amountColor = const Color(0xFF4E6AFF);
      prefix = "C ";
    }

    if (!expense.isPaid) {
      amountColor = Colors.orange;
      prefix = "⏳ ";
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
            offset: const Offset(0, 3)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: expense.iconColor.withOpacity(0.1), 
                radius: 20, 
                child: Icon(expense.icon, color: expense.iconColor, size: 20)
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    
                    if (expense.contactName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          // Shows Customer or Supplier
                          expense.isIncome ? "Customer: ${expense.contactName}" : "Payee: ${expense.contactName}",
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ),

                    if (expense.quantity != null && expense.quantity! > 0)
                      Text("${expense.quantity} pcs @ ₱${(expense.amount / expense.quantity!).toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                    else
                      Text(expense.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$prefix₱${expense.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: amountColor)),
                  const SizedBox(height: 2),
                  Text(expense.dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!expense.isPaid && onMarkAsPaid != null && !expense.isCapital) ...[
                InkWell(
                  onTap: onMarkAsPaid,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          expense.isIncome ? "Received" : "Paid",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Edit Button
              InkWell(
                onTap: onEdit, 
                borderRadius: BorderRadius.circular(8), 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  decoration: BoxDecoration(
                    color: AppColors.background, 
                    borderRadius: BorderRadius.circular(8)
                  ), 
                  child: const Text("Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))
                )
              ),
            ],
          )
        ],
      ),
    );
  }
}
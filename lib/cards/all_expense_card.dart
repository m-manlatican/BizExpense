import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Subtle shadow matching the dashboard cards
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
          // 1. Icon, Title, and Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              CircleAvatar(
                backgroundColor: expense.iconColor.withOpacity(0.1), 
                radius: 20, 
                child: Icon(expense.icon, color: expense.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              
              // Title Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 16, 
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount and Date Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      // Kept black to match "Total Spent" text in Dashboard
                      color: Colors.black87, 
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 2. Category Row (Aligned with text)
          Row(
            children: [
              const SizedBox(width: 54), // Align with title
              Text(
                expense.category,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // 3. Notes
          if (expense.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 54, top: 4),
              child: Text(
                expense.notes,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // 4. Buttons (Themed)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit Button - THEME CHANGE: Uses Dashboard Green
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  // Primary Green text
                  foregroundColor: const Color(0xFF00B383), 
                  // Very light green background
                  backgroundColor: const Color(0xFFE5F8F2),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: onEdit,
              ),
              const SizedBox(width: 10),
              
              // Delete Button - Kept Soft Red for contrast/safety
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFFDE706C),
                  backgroundColor: const Color(0xFFFBECEB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
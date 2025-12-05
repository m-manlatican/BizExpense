import 'package:expense_tracker_3_0/app_colors.dart';
// 🔥 CRITICAL IMPORTS: These lines fix the "Red Line" error
import 'package:expense_tracker_3_0/cards/category_breakdown_card.dart';
import 'package:expense_tracker_3_0/cards/report_summary_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  final double totalBudget;
  final VoidCallback? onBackTap;
  final FirestoreService _firestoreService = FirestoreService(); 

  ReportsPage({
    super.key, 
    required this.totalBudget, 
    this.onBackTap
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => onBackTap != null ? onBackTap!() : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Reports",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // Content
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _firestoreService.getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                final expenses = snapshot.data ?? [];
                // Calculate total spent based on active expenses
                final activeExpenses = expenses.where((e) => !e.isDeleted).toList();
                final totalSpent = activeExpenses.fold(0.0, (sum, item) => sum + item.amount);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 🔥 These widgets should now be recognized
                      ReportSummaryCard(
                        totalBudget: totalBudget, 
                        totalSpent: totalSpent, 
                        expenseCount: activeExpenses.length,
                      ),
                      const SizedBox(height: 16),
                      CategoryBreakdownCard(expenses: activeExpenses),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
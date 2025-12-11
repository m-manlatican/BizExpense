import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/category_breakdown_card.dart';
import 'package:expense_tracker_3_0/cards/report_summary_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  final VoidCallback? onBackTap;
  final FirestoreService _firestoreService = FirestoreService(); 

  ReportsPage({
    super.key, 
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
                      "Business Reports",
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
                
                final allTransactions = snapshot.data ?? [];
                
                // 🔥 LOGIC UPDATE: Use ALL transactions (including deleted) for reports.
                // This ensures swiped items still count towards Profit/Loss.
                final calculationTransactions = allTransactions; 
                
                // Separate Income & Expenses
                final totalIncome = calculationTransactions
                    .where((e) => e.isIncome)
                    .fold(0.0, (sum, item) => sum + item.amount);
                
                final totalExpenses = calculationTransactions
                    .where((e) => !e.isIncome && !e.isCapital)
                    .fold(0.0, (sum, item) => sum + item.amount);

                // Lists for Breakdown Charts
                final expenseList = calculationTransactions.where((e) => !e.isIncome && !e.isCapital).toList();
                final incomeList = calculationTransactions.where((e) => e.isIncome).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1. Profit & Loss Summary
                      ReportSummaryCard(
                        totalIncome: totalIncome, 
                        totalExpenses: totalExpenses,
                      ),
                      const SizedBox(height: 16),
                      
                      // 2. Income Breakdown (Sales Source)
                      if (incomeList.isNotEmpty)
                        CategoryBreakdownCard(
                          title: "Income Sources",
                          expenses: incomeList,
                          isIncome: true,
                        ),
                        
                      const SizedBox(height: 16),

                      // 3. Expense Breakdown (Cost Center)
                      if (expenseList.isNotEmpty)
                        CategoryBreakdownCard(
                          title: "Expense Breakdown",
                          expenses: expenseList,
                          isIncome: false,
                        ),
                        
                      if (incomeList.isEmpty && expenseList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text("No transactions available.", style: TextStyle(color: Colors.grey)),
                        ),

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
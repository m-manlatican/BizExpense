// ... [imports] ...
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ExpenseHistoryPage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  ExpenseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header ...
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
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
                      "History (Deleted)",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _firestoreService.getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                final deletedExpenses = (snapshot.data ?? []).where((e) => e.isDeleted).toList();

                if (deletedExpenses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No history found.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: deletedExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = deletedExpenses[index];
                    return _HistoryCard(expense: expense, service: _firestoreService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Expense expense;
  final FirestoreService service;

  const _HistoryCard({required this.expense, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                radius: 20,
                child: Icon(expense.icon, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
                ),
              ),
              Text(
                '₱${expense.amount.toStringAsFixed(2)}', // 🔥 CHANGED TO PESO
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.restore, size: 18, color: AppColors.primary),
                label: const Text("Restore", style: TextStyle(color: AppColors.primary)),
                onPressed: () => service.restoreExpense(expense.id),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.expense),
                label: const Text("Delete Forever", style: TextStyle(color: AppColors.expense)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Permanently?", style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text("This will remove the expense from your total spent forever."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await service.permanentlyDeleteExpense(expense.id);
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
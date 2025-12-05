import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:flutter/material.dart';

class ReportSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final int expenseCount;

  const ReportSummaryCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = totalBudget - totalSpent;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Summary",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryBox(label: "Total Budget", amount: totalBudget, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryBox(label: "Total Spent", amount: totalSpent, color: AppColors.expense)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryBox(label: "Remaining", amount: remaining, color: remaining >= 0 ? AppColors.primary : AppColors.expense)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Expenses", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text("$expenseCount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryBox({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text("₱${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
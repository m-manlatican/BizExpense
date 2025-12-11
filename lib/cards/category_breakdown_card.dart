import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/widgets/simple_pie_chart.dart';
import 'package:flutter/material.dart';

class CategoryBreakdownCard extends StatelessWidget {
  final String title;
  final List<Expense> expenses;
  final bool isIncome;

  const CategoryBreakdownCard({
    super.key,
    required this.title,
    required this.expenses,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};

    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      
      // 🔥 OPTIMIZED: Fetch the latest color definition from the Model.
      // This ensures the Pie Chart uses your NEW colors immediately, 
      // instead of using the old colors stored in the database.
      categoryColors[e.category] = Expense.getCategoryDetails(e.category)['color'] as Color;
    }

    final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);
    
    final List<MapEntry<String, double>> sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartData> pieData = sortedCategories.map((entry) {
      return PieChartData(
        entry.value, 
        categoryColors[entry.key] ?? Colors.grey, 
        entry.key
      );
    }).toList();

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          if (totalAmount > 0)
            Center(
              child: SimplePieChart(
                data: pieData,
                radius: 80, 
              ),
            )
          else 
            const Center(child: Text("No data to display")),

          const SizedBox(height: 30),

          ...sortedCategories.map((entry) {
            final categoryName = entry.key;
            final amount = entry.value;
            final color = categoryColors[categoryName] ?? Colors.grey;
            final percentage = totalAmount > 0 ? (amount / totalAmount) : 0.0;
            final percentString = (percentage * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 6,
                            backgroundColor: color,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "$categoryName ",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                TextSpan(
                                  text: "($percentString%)",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "₱${amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
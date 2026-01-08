import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/models/inventory_model.dart';
import 'package:expense_tracker_3_0/pages/add_expense_page.dart';
import 'package:flutter/material.dart';

class ProductListCard extends StatelessWidget {
  final List<InventoryItem> items;
  final List<Expense> allExpenses;

  const ProductListCard({
    super.key,
    required this.items,
    required this.allExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // 🔥 PERFORMANCE OPTIMIZATION:
    // Create a lookup map for the latest prices so we don't loop through
    // 1000s of expenses for every single product row.
    final Map<String, double> priceMap = {};
    
    // Expenses are already sorted by date descending (newest first).
    // We just grab the first expense for each product name.
    for (var e in allExpenses) {
      if (!e.isIncome && !e.isCapital) {
        final key = e.title.toLowerCase();
        if (!priceMap.containsKey(key)) {
          double price = e.amount;
          if (e.quantity != null && e.quantity! > 0) {
             price = e.amount / e.quantity!;
          }
          priceMap[key] = price;
        }
      }
    }

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "Current Products/Others", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => const Divider(height: 24, color: Color(0xFFEFF3FA)),
            itemBuilder: (context, index) {
              final item = items[index];
              final double? lastPrice = priceMap[item.name.toLowerCase()];

              return Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastPrice != null 
                              ? "Original Price: ₱${lastPrice.toStringAsFixed(2)}"
                              : "No purchase history",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "${item.quantity} pcs", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Restock Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpensePage(
                            prefillTitle: item.name,          
                            prefillCategory: 'Inventory',     
                            prefillType: TransactionType.expense,
                            prefillPrice: lastPrice, 
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary, 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: const Text(
                        "Restock", 
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
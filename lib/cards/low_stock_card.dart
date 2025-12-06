import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:expense_tracker_3_0/models/inventory_model.dart';
import 'package:expense_tracker_3_0/pages/add_expense_page.dart'; // 🔥 Import
import 'package:flutter/material.dart';

class LowStockCard extends StatelessWidget {
  final List<InventoryItem> items;

  const LowStockCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 20),
              SizedBox(width: 8),
              Text("Low Stock Alert", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.expense.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("${item.quantity} left", style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    // 🔥 RESTOCK BUTTON
                    InkWell(
                      onTap: () {
                        // Open AddExpensePage with pre-filled data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpensePage(
                              prefillTitle: item.name,          // Fill Name
                              prefillCategory: 'Inventory',     // Fill Category
                              prefillType: TransactionType.expense, // Fill Type
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text("Restock", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/white_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart'; // Needed for type
import 'package:expense_tracker_3_0/models/inventory_model.dart';
import 'package:expense_tracker_3_0/pages/add_expense_page.dart'; 
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';

class LowStockCard extends StatelessWidget {
  final List<InventoryItem> items;
  final List<Expense> allExpenses; // 🔥 NEW: Needed to calculate original price

  const LowStockCard({
    super.key, 
    required this.items,
    required this.allExpenses,
  });

  void _ignoreItem(BuildContext context, String itemId) async {
    final FirestoreService service = FirestoreService();
    await service.ignoreInventoryItem(itemId);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item removed from alerts."), duration: Duration(seconds: 1)),
      );
    }
  }

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
          ...items.map((item) {
            
            // 🔥 LOGIC: Find last purchase price for this item
            double? lastPrice;
            try {
              // Find the most recent expense with this title
              // (List is already sorted by date desc in dashboard, but we can play safe)
              final matching = allExpenses.where((e) => 
                  e.title.toLowerCase() == item.name.toLowerCase() && 
                  !e.isIncome && // Must be an expense
                  !e.isCapital   // Not capital
              );
              
              if (matching.isNotEmpty) {
                 final lastExp = matching.first; // Most recent
                 if (lastExp.quantity != null && lastExp.quantity! > 0) {
                   lastPrice = lastExp.amount / lastExp.quantity!;
                 } else {
                   lastPrice = lastExp.amount;
                 }
              }
            } catch (e) {
              // Fallback
              lastPrice = null;
            }

            return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lastPrice != null)
                        Text(
                          "Last Cost: ₱${lastPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
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
                    
                    // 🔥 IGNORE BUTTON
                    InkWell(
                      onTap: () => _ignoreItem(context, item.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.visibility_off_outlined, size: 20, color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // 🔥 RESTOCK BUTTON
                    InkWell(
                      onTap: () {
                        // Open AddExpensePage with pre-filled data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpensePage(
                              prefillTitle: item.name,          
                              prefillCategory: 'Inventory',     
                              prefillType: TransactionType.expense,
                              prefillPrice: lastPrice, // 🔥 Pass calculated price
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
          );
          }),
        ],
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_3_0/widgets/form_fields.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  late Stream<double> _budgetStream;
  late Stream<List<Expense>> _expensesStream;

  String selectedCategory = 'Food';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _budgetStream = _firestoreService.getUserBudgetStream();
    _expensesStream = _firestoreService.getExpensesStream();
    
    // Ensure default selection is valid
    if (!Expense.categories.contains(selectedCategory)) {
      selectedCategory = Expense.categories.first;
    }
  }

  Future<void> _saveExpense(double availableBalance, double totalBudget) async {
    final title = titleController.text.trim();
    final amountText = amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields.')));
      return;
    }

    final double amount = double.parse(amountText);

    if (totalBudget <= 0) {
      _showErrorDialog("No Budget Set", "You need to set a budget in the Dashboard before adding expenses.");
      return;
    }

    if (amount > availableBalance) {
      _showErrorDialog("Insufficient Budget", "This expense (₱$amount) exceeds your available balance (₱$availableBalance).");
      return;
    }

    try {
      setState(() => isLoading = true);
      final now = DateTime.now(); 
      
      // 🔥 USE SHARED HELPER
      final categoryDetails = Expense.getCategoryDetails(selectedCategory);
      
      final newExpense = Expense(
        id: '', title: title, category: selectedCategory, amount: amount,
        dateLabel: "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}",
        date: Timestamp.now(), notes: notesController.text.trim(),
        iconCodePoint: (categoryDetails['icon'] as IconData).codePoint, 
        iconColorValue: (categoryDetails['color'] as Color).value,
      );
      
      await _firestoreService.addExpense(newExpense);
      if (!mounted) return;
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); if (title == "No Budget Set") Navigator.pop(context); },
            child: Text(title == "No Budget Set" ? "Go to Dashboard" : "Okay", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _budgetStream,
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }

        final double totalBudget = budgetSnapshot.data ?? 0.00;

        return StreamBuilder<List<Expense>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
            }

            double totalSpent = 0.0;
            if (expenseSnapshot.hasData) {
              final allExpenses = expenseSnapshot.data!;
              totalSpent = allExpenses.fold(0.0, (sum, item) => sum + item.amount);
            }
            final double availableBalance = totalBudget - totalSpent;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
                    decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
                    child: Row(
                      children: [
                        InkWell(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                        const Expanded(child: Center(child: Text("Add Expense", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)))),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: totalBudget <= 0 ? AppColors.expense.withOpacity(0.1) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: totalBudget <= 0 ? AppColors.expense : AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(totalBudget <= 0 ? "No Budget Set" : "Available Balance", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: totalBudget <= 0 ? AppColors.expense : AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Text("₱${availableBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: totalBudget <= 0 ? AppColors.expense : AppColors.textPrimary)),
                                  ],
                                ),
                                if (totalBudget <= 0) ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text("Set Budget", style: TextStyle(fontSize: 12))) else Icon(Icons.account_balance_wallet, color: AppColors.primary.withOpacity(0.5), size: 32),
                              ],
                            ),
                          ),
                          const FormLabel('Expense Name'), const SizedBox(height: 6), RoundedTextField(controller: titleController, hintText: 'e.g. Lunch at Mcdonalds'), const SizedBox(height: 16),
                          const FormLabel('Amount'), const SizedBox(height: 6), RoundedTextField(controller: amountController, prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), keyboardType: const TextInputType.numberWithOptions(decimal: true), hintText: '0.00'), const SizedBox(height: 16),
                          const FormLabel('Category'), const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16), 
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), 
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory, 
                                isExpanded: true, 
                                icon: const Icon(Icons.keyboard_arrow_down_rounded), 
                                borderRadius: BorderRadius.circular(14), 
                                // 🔥 USE SHARED CATEGORIES
                                items: Expense.categories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(), 
                                onChanged: (newValue) => setState(() => selectedCategory = newValue!)
                              ),
                            ),
                          ), 
                          const SizedBox(height: 16),
                          const FormLabel('Notes (Optional)'), const SizedBox(height: 6), RoundedTextField(controller: notesController, hintText: 'Add details...', maxLines: 3), const SizedBox(height: 24),
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: isLoading ? null : () => _saveExpense(availableBalance, totalBudget), icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white), label: Text(isLoading ? "Saving..." : "Save Expense", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
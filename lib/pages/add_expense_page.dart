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

enum TransactionType { expense, income }

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController amountController = TextEditingController(); 

  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Expense>> _expensesStream;
  late Stream<double> _budgetStream; 

  TransactionType _type = TransactionType.expense; 
  String selectedCategory = Expense.expenseCategories.first;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _expensesStream = _firestoreService.getExpensesStream();
    _budgetStream = _firestoreService.getUserBudgetStream();
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      selectedCategory = _type == TransactionType.income 
          ? Expense.incomeCategories.first 
          : Expense.expenseCategories.first;
      
      priceController.clear();
      qtyController.clear();
      amountController.clear();
    });
  }

  Future<void> _saveTransaction(double availableBalance) async {
    // 🔥 Local isIncome for logic
    bool isIncome = _type == TransactionType.income;

    final title = titleController.text.trim();
    
    if (title.isEmpty) {
      _showSnack('Please enter a description.');
      return;
    }

    double finalAmount = 0.0;
    int? finalQty;

    final price = double.tryParse(priceController.text.trim());
    final qty = int.tryParse(qtyController.text.trim());
    
    if (price != null && qty != null && price > 0 && qty > 0) {
      finalAmount = price * qty;
      finalQty = qty;
    } else {
      _showSnack('Please enter valid Price and Quantity.');
      return;
    }

    if (!isIncome) {
      if (availableBalance <= 0) {
        _showErrorDialog(
          "Insufficient Funds", 
          "You have ₱0.00 cash on hand. Go to Dashboard to add Capital, or record a Sale first.",
          isCritical: true 
        );
        return;
      }
      if (finalAmount > availableBalance) {
        _showErrorDialog(
          "Insufficient Funds", 
          "This expense (₱$finalAmount) exceeds your available cash (₱${availableBalance.toStringAsFixed(2)})."
        );
        return;
      }
    }

    try {
      setState(() => isLoading = true);
      final now = DateTime.now(); 
      final categoryDetails = Expense.getCategoryDetails(selectedCategory);
      
      final newTransaction = Expense(
        id: '', 
        title: title, 
        category: selectedCategory, 
        amount: finalAmount,
        quantity: finalQty, 
        isIncome: isIncome,
        isCapital: false, 
        dateLabel: "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}",
        date: Timestamp.now(), 
        notes: notesController.text.trim(),
        iconCodePoint: (categoryDetails['icon'] as IconData).codePoint, 
        iconColorValue: (categoryDetails['color'] as Color).value,
      );
      
      await _firestoreService.addExpense(newTransaction);
      if (!mounted) return;
      
      String msg = isIncome ? "Sale Recorded!" : "Expense Recorded!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
      Navigator.pop(context); 
      
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.expense));
  }

  void _showErrorDialog(String title, String message, {bool isCritical = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          if (isCritical) 
            ElevatedButton(
              onPressed: () { 
                Navigator.pop(ctx); 
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Go to Dashboard"),
            )
          else 
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Okay", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Define isIncome here for the UI
    final bool isIncome = _type == TransactionType.income;
    
    final List<String> currentCategories = isIncome 
        ? Expense.incomeCategories 
        : Expense.expenseCategories;

    return StreamBuilder<double>(
      stream: _budgetStream,
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        final double manualCapital = budgetSnapshot.data ?? 0.00;

        return StreamBuilder<List<Expense>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
            }

            double totalSpent = 0.0;
            double totalIncome = 0.0;
            
            if (expenseSnapshot.hasData) {
              final all = expenseSnapshot.data!.where((e) => !e.isDeleted).toList();
              totalIncome = all.where((e) => e.isIncome).fold(0.0, (sum, item) => sum + item.amount);
              totalSpent = all.where((e) => !e.isIncome && !e.isCapital).fold(0.0, (sum, item) => sum + item.amount);
            }
            
            final double cashOnHand = (manualCapital + totalIncome) - totalSpent;

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
                        const Expanded(child: Center(child: Text("Add Transaction", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)))),
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
                          
                          // Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                Expanded(child: _buildToggleOption("Expense", !isIncome, AppColors.expense)),
                                Expanded(child: _buildToggleOption("Income (Sales)", isIncome, AppColors.success)),
                              ],
                            ),
                          ),

                          // Cash Display
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: cashOnHand <= 0 ? AppColors.expense.withOpacity(0.1) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cashOnHand <= 0 ? AppColors.expense : AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cashOnHand <= 0 ? "No Cash Available" : "Current Cash on Hand", 
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cashOnHand <= 0 ? AppColors.expense : AppColors.primary)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₱${cashOnHand.toStringAsFixed(2)}", 
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cashOnHand <= 0 ? AppColors.expense : AppColors.textPrimary)
                                    ),
                                  ],
                                ),
                                Icon(Icons.account_balance_wallet, color: AppColors.primary.withOpacity(0.5), size: 32),
                              ],
                            ),
                          ),

                          const FormLabel('Description'), 
                          const SizedBox(height: 6), 
                          RoundedTextField(
                            controller: titleController, 
                            // 🔥 No error here now
                            hintText: isIncome ? 'e.g. Daily Product Sales' : 'e.g. Inventory Restock',
                            textInputAction: TextInputAction.next,
                          ), 
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FormLabel('Price (per unit)'), 
                                    const SizedBox(height: 6),
                                    RoundedTextField(
                                      controller: priceController, 
                                      prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600)),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      hintText: '0.00',
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FormLabel('Qty'), 
                                    const SizedBox(height: 6),
                                    RoundedTextField(
                                      controller: qtyController, 
                                      prefix: const Icon(Icons.numbers, size: 18),
                                      keyboardType: TextInputType.number,
                                      hintText: '1',
                                      textInputAction: TextInputAction.done,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          
                          const FormLabel('Category'), 
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16), 
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), 
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory, 
                                isExpanded: true, 
                                icon: const Icon(Icons.keyboard_arrow_down_rounded), 
                                borderRadius: BorderRadius.circular(14), 
                                items: currentCategories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(), 
                                onChanged: (newValue) => setState(() => selectedCategory = newValue!)
                              ),
                            ),
                          ), 
                          const SizedBox(height: 16),
                          
                          const FormLabel('Notes (Optional)'), 
                          const SizedBox(height: 6), 
                          RoundedTextField(
                            controller: notesController, 
                            hintText: 'Add details...', 
                            maxLines: 3
                          ), 
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity, 
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : () => _saveTransaction(cashOnHand), 
                              icon: isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Icon(Icons.check_circle_outline, color: Colors.white), 
                              label: Text(
                                isLoading ? "Saving..." : "Save Record", 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ), 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary, 
                                padding: const EdgeInsets.symmetric(vertical: 15), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), 
                                elevation: 4
                              )
                            )
                          ),
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

  Widget _buildToggleOption(String label, bool isSelected, Color activeColor) {
    return GestureDetector(
      onTap: () {
        if (label == "Expense") _setType(TransactionType.expense);
        if (label == "Income (Sales)") _setType(TransactionType.income);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
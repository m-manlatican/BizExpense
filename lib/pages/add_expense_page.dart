import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_3_0/widgets/form_fields.dart';

class AddExpensePage extends StatefulWidget {
  final String? prefillTitle;
  final String? prefillCategory;
  final TransactionType? prefillType;

  const AddExpensePage({
    super.key,
    this.prefillTitle,
    this.prefillCategory,
    this.prefillType,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

enum TransactionType { expense, income }

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController titleController = TextEditingController(); // Used for Expense (Text)
  final TextEditingController priceController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  String? _selectedContactType; 
  // 🔥 NEW: Selected Product for Income Dropdown
  String? _selectedProductDescription; 

  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Expense>> _expensesStream;
  late Stream<double> _budgetStream; 

  TransactionType _type = TransactionType.expense; 
  String selectedCategory = Expense.expenseCategories.first;
  bool isPaid = true; 
  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _expensesStream = _firestoreService.getExpensesStream();
    _budgetStream = _firestoreService.getUserBudgetStream();

    if (widget.prefillType != null) {
      _type = widget.prefillType!;
    }
    if (widget.prefillCategory != null) {
      selectedCategory = widget.prefillCategory!;
    } else {
      selectedCategory = _type == TransactionType.income 
          ? Expense.incomeCategories.first 
          : Expense.expenseCategories.first;
    }
    if (widget.prefillTitle != null) {
      titleController.text = widget.prefillTitle!;
      // If income, try to preselect the dropdown
      if (_type == TransactionType.income) {
        _selectedProductDescription = widget.prefillTitle;
      }
    }
    
    _selectedContactType = null;
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      selectedCategory = _type == TransactionType.income 
          ? Expense.incomeCategories.first 
          : Expense.expenseCategories.first;
      
      _selectedContactType = null;
      _selectedProductDescription = null; // Reset product selection
      
      titleController.clear();
      priceController.clear();
      qtyController.clear();
    });
  }

  Future<void> _pickDate() async {
     final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white, 
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction(double availableBalance) async {
    // 🔥 LOGIC: Use Dropdown value for Income, Text Controller for Expense
    String title = '';
    if (_type == TransactionType.income) {
      title = _selectedProductDescription ?? '';
    } else {
      title = titleController.text.trim();
    }

    if (title.isEmpty) { _showSnack('Please enter or select a description.'); return; }

    double finalAmount = 0.0;
    int? finalQty;

    final price = double.tryParse(priceController.text.trim());
    final qtyString = qtyController.text.trim();
    
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid Price.');
      return;
    }

    if (qtyString.isNotEmpty) {
      finalQty = int.tryParse(qtyString);
      if (finalQty == null || finalQty <= 0) {
        _showSnack('Quantity must be a valid number.');
        return;
      }
    }

    bool isCapital = false; 
    if (!isCapital && _selectedContactType == null) {
      _showSnack(_type == TransactionType.income ? "Please select a Customer Type." : "Please select a Payee Type.");
      return;
    }

    finalAmount = price * (finalQty ?? 1);

    if (_type == TransactionType.expense && isPaid) {
      if (availableBalance <= 0) {
        _showErrorDialog("Insufficient Funds", "You have ₱0.00 cash on hand.", isCritical: true);
        return;
      }
      if (finalAmount > availableBalance) {
        _showErrorDialog("Insufficient Funds", "This expense exceeds your available cash.");
        return;
      }
    }

    try {
      setState(() => isLoading = true);

      // 🔥 STOCK LOGIC: Recognizes both 'Product Sales' (Income) and 'Product' (Expense)
      if (_type == TransactionType.income && selectedCategory == "Product Sales") {
         await _firestoreService.updateStock(title, -(finalQty ?? 1)); 
      } 
      else if (_type == TransactionType.expense && (selectedCategory == "Inventory" || selectedCategory == "Product")) {
         // Works for both "Inventory" (Old) and "Product" (New)
         bool updateStock = await showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text("Update Stock?", style: TextStyle(fontWeight: FontWeight.bold)),
             content: Text("Do you want to add ${finalQty ?? 1} units to '$title' inventory?"),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
               TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes", style: TextStyle(fontWeight: FontWeight.bold))),
             ],
           )
         ) ?? false;

         if (updateStock) {
           await _firestoreService.updateStock(title, finalQty ?? 1);
         }
      }

      final categoryDetails = Expense.getCategoryDetails(selectedCategory);
      final dateLabel = "${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}";

      final newTransaction = Expense(
        id: '',
        title: title,
        category: selectedCategory,
        amount: finalAmount,
        quantity: finalQty,
        isIncome: _type == TransactionType.income,
        isCapital: false,
        isPaid: isPaid,
        contactName: _selectedContactType!, 
        dateLabel: dateLabel,
        date: Timestamp.fromDate(_selectedDate),
        notes: notesController.text.trim(),
        iconCodePoint: (categoryDetails['icon'] as IconData).codePoint,
        iconColorValue: (categoryDetails['color'] as Color).value,
      );

      await _firestoreService.addExpense(newTransaction);
      
      if (!mounted) return;
      
      String msg = _type == TransactionType.income ? "Sale Recorded!" : "Expense Recorded!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
      Navigator.pop(context); 
      
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.expense));

  void _showErrorDialog(String title, String message, {bool isCritical = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          if (isCritical) 
            ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text("Go to Dashboard"))
          else 
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Okay"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isIncome = _type == TransactionType.income;
    List<String> currentCategories = isIncome ? Expense.incomeCategories : Expense.expenseCategories;
    List<String> currentContactTypes = isIncome ? Expense.incomeContactTypes : Expense.expenseContactTypes;
    String dateText = "${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}";
    bool isCapital = false; 

    return StreamBuilder<double>(
      stream: _budgetStream,
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        final double manualCapital = budgetSnapshot.data ?? 0.00;

        return StreamBuilder<List<Expense>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

            // 🔥 EXTRACT PRODUCTS FOR DROPDOWN
            // We get all expenses, filter for 'Product' category (or Inventory), and get unique titles.
            List<String> productList = [];
            double totalSpent = 0.0;
            double totalIncome = 0.0;
            
            if (expenseSnapshot.hasData) {
              final all = expenseSnapshot.data!.toList();
              
              // Logic for Dropdown: Extract unique titles where category is "Product"
              final products = all
                  .where((e) => e.category == 'Product') // Filter strictly for 'Product' as requested
                  .map((e) => e.title)
                  .toSet() // Remove duplicates
                  .toList();
              products.sort(); // Alphabetical order
              productList = products;

              totalIncome = all.where((e) => e.isIncome && e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
              totalSpent = all.where((e) => !e.isIncome && !e.isCapital && e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                            child: Row(children: [Expanded(child: _buildToggleOption("Expense", !isIncome, AppColors.expense)), Expanded(child: _buildToggleOption("Income (Sales)", isIncome, AppColors.success))]),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: cashOnHand <= 0 ? AppColors.expense.withOpacity(0.1) : AppColors.secondary, borderRadius: BorderRadius.circular(16), border: Border.all(color: cashOnHand <= 0 ? AppColors.expense : AppColors.primary.withOpacity(0.3))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cashOnHand <= 0 ? "No Cash Available" : "Current Cash on Hand", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cashOnHand <= 0 ? AppColors.expense : AppColors.primary)), const SizedBox(height: 4), Text("₱${cashOnHand.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))]), Icon(Icons.account_balance_wallet, color: AppColors.primary.withOpacity(0.5), size: 32)]),
                          ),
                          
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
                              child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary), const SizedBox(width: 12), Text("Date: $dateText", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)), const Spacer(), const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary)]),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const FormLabel('Description'), 
                          const SizedBox(height: 6),
                          
                          // 🔥 UI SWITCH: Dropdown for Income, Text for Expense
                          if (isIncome)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedProductDescription,
                                  isExpanded: true,
                                  hint: Text(
                                    productList.isEmpty ? "No products added yet" : "Select Product",
                                    style: const TextStyle(color: AppColors.textSecondary)
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  borderRadius: BorderRadius.circular(14),
                                  items: productList.map((String value) {
                                    return DropdownMenuItem(value: value, child: Text(value));
                                  }).toList(),
                                  onChanged: productList.isEmpty 
                                    ? null // Disable if no products
                                    : (newValue) => setState(() => _selectedProductDescription = newValue),
                                ),
                              ),
                            )
                          else
                            RoundedTextField(
                              controller: titleController, 
                              hintText: 'e.g. Inventory Restock', 
                              textInputAction: TextInputAction.next
                            ),
                            
                          const SizedBox(height: 16),
                          
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FormLabel('Price'), const SizedBox(height: 6), RoundedTextField(controller: priceController, prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600)), keyboardType: TextInputType.number, textInputAction: TextInputAction.next)])),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FormLabel('Qty (Optional)'), const SizedBox(height: 6), RoundedTextField(controller: qtyController, keyboardType: TextInputType.number, hintText: '1', textInputAction: TextInputAction.done)])),
                          ]),
                          const SizedBox(height: 16),
                          
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            title: Text(isIncome ? "Payment Received?" : "Paid Immediately?", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            subtitle: Text(isPaid ? (isIncome ? "Cash added to balance." : "Cash deducted.") : (isIncome ? "Mark as Credit." : "Mark as Debt."), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            value: isPaid,
                            onChanged: (val) => setState(() => isPaid = val ?? true),
                          ),
                          const SizedBox(height: 10),

                          if (!isCapital) ...[
                            FormLabel(isIncome ? "Customer Type" : "Payee Type"),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedContactType,
                                  isExpanded: true,
                                  hint: const Text("Select Type", style: TextStyle(color: AppColors.textSecondary)),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  borderRadius: BorderRadius.circular(14),
                                  items: currentContactTypes.map((String value) {
                                    return DropdownMenuItem(value: value, child: Text(value));
                                  }).toList(),
                                  onChanged: (newValue) => setState(() => _selectedContactType = newValue),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const FormLabel('Category'), const SizedBox(height: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedCategory, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded), borderRadius: BorderRadius.circular(14), items: currentCategories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (newValue) => setState(() => selectedCategory = newValue!)))), const SizedBox(height: 16),
                          const FormLabel('Notes (Optional)'), const SizedBox(height: 6), RoundedTextField(controller: notesController, hintText: 'Add details...', maxLines: 3), const SizedBox(height: 24),
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: isLoading ? null : () => _saveTransaction(cashOnHand), icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline, color: Colors.white), label: Text(isLoading ? "Saving..." : "Save Record", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4))),
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
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? activeColor : AppColors.textSecondary))),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:expense_tracker_3_0/widgets/form_fields.dart'; 
import 'package:flutter/material.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;
  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController qtyController;
  late TextEditingController notesController;
  late TextEditingController amountController;
  
  String? _selectedContactType; 
  
  late String category;
  late bool isIncome;
  late bool isCapital;
  late bool isPaid;
  late DateTime selectedDate; 
  
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.expense.title);
    notesController = TextEditingController(text: widget.expense.notes);
    
    category = widget.expense.category;
    isIncome = widget.expense.isIncome;
    isCapital = widget.expense.isCapital; 
    isPaid = widget.expense.isPaid;
    selectedDate = widget.expense.date.toDate();

    List<String> validTypes = isIncome ? Expense.incomeContactTypes : Expense.expenseContactTypes;
    if (validTypes.contains(widget.expense.contactName)) {
      _selectedContactType = widget.expense.contactName;
    } else {
      _selectedContactType = validTypes.contains('Other') ? 'Other' : validTypes.first;
    }

    amountController = TextEditingController();
    priceController = TextEditingController();
    qtyController = TextEditingController();

    if (isCapital) {
      amountController.text = widget.expense.amount.toStringAsFixed(2);
    } else {
      if (widget.expense.quantity != null && widget.expense.quantity! > 0) {
        qtyController.text = widget.expense.quantity.toString();
        double price = widget.expense.amount / widget.expense.quantity!;
        priceController.text = price.toStringAsFixed(2);
      } else {
        qtyController.text = "1"; 
        priceController.text = widget.expense.amount.toStringAsFixed(2);
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _handleUpdateExpense() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description is required.')));
      return;
    }

    double finalAmount = 0.0;
    int? finalQty;

    if (isCapital) {
      final amount = double.tryParse(amountController.text.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Amount required.')));
        return;
      }
      finalAmount = amount;
    } else {
      final price = double.tryParse(priceController.text.replaceAll(',', ''));
      final qtyString = qtyController.text.trim();
      
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Price required.')));
        return;
      }
      
      if (qtyString.isNotEmpty) {
        finalQty = int.tryParse(qtyString);
        if (finalQty == null || finalQty <= 0) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Quantity required.')));
           return;
        }
      }
      finalAmount = price * (finalQty ?? 1);
    }

    setState(() => isLoading = true); 

    try {
      // ---------------------------------------------------------
      // INVENTORY SYNC LOGIC
      // ---------------------------------------------------------
      bool isInventoryCat(String c) => c == 'Inventory' || c == 'Product';

      final String oldCategory = widget.expense.category;
      final String newCategory = category;
      
      final bool wasExpense = !widget.expense.isIncome && !widget.expense.isCapital;
      final bool isExpense = !isIncome && !isCapital;

      final bool wasInventoryItem = wasExpense && isInventoryCat(oldCategory);
      final bool isInventoryItem = isExpense && isInventoryCat(newCategory);

      final String oldTitle = widget.expense.title;
      final String newTitle = nameController.text.trim();
      final int oldQty = widget.expense.quantity ?? 1;
      final int newQty = finalQty ?? 1;

      // 1. Inventory -> Other: REMOVE Stock
      if (wasInventoryItem && !isInventoryItem) {
        await _firestoreService.updateStock(oldTitle, -oldQty);
      }
      
      // 2. Other -> Inventory: ADD Stock
      else if (!wasInventoryItem && isInventoryItem) {
        await _firestoreService.updateStock(newTitle, newQty);
      }
      
      // 3. Inventory -> Inventory (Change details)
      else if (wasInventoryItem && isInventoryItem) {
        if (oldTitle != newTitle) {
          // Name changed: Remove old, add new
          await _firestoreService.updateStock(oldTitle, -oldQty);
          await _firestoreService.updateStock(newTitle, newQty);
        } else if (oldQty != newQty) {
          // Only qty changed: Adjust diff
          final int diff = newQty - oldQty;
          await _firestoreService.updateStock(newTitle, diff);
        }
      }
      // ---------------------------------------------------------

      final dateLabel = "${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.year}";

      final updatedExpense = Expense(
        id: widget.expense.id, 
        title: nameController.text.trim(),
        amount: finalAmount,
        quantity: finalQty, 
        category: category,
        dateLabel: dateLabel, 
        date: Timestamp.fromDate(selectedDate), 
        notes: notesController.text.trim(),
        contactName: _selectedContactType ?? '',
        isIncome: isIncome,
        isCapital: isCapital, 
        isPaid: isPaid,       
        isDeleted: widget.expense.isDeleted,
      );

      await _firestoreService.updateExpense(updatedExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record Updated Successfully"), backgroundColor: AppColors.success));
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating: $e"), backgroundColor: AppColors.expense));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayCategories = [];
    if (isCapital) displayCategories = Expense.capitalCategories;
    else if (isIncome) displayCategories = Expense.incomeCategories;
    else displayCategories = Expense.expenseCategories;

    if (!displayCategories.contains(category)) {
      displayCategories.add(category);
    }
    
    List<String> displayContactTypes = isIncome ? Expense.incomeContactTypes : Expense.expenseContactTypes;
    String dateText = "${selectedDate.month}/${selectedDate.day}/${selectedDate.year}";

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
                const Expanded(child: Center(child: Text("Edit Record", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)))),
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
                  RoundedTextField(controller: nameController, hintText: 'Description...', textInputAction: TextInputAction.next), 
                  const SizedBox(height: 16),

                  if (isCapital) ...[
                    const FormLabel('Amount'), 
                    const SizedBox(height: 6),
                    RoundedTextField(controller: amountController, prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600)), keyboardType: TextInputType.number, textInputAction: TextInputAction.done),
                  ] else ...[
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const FormLabel('Price'), const SizedBox(height: 6),
                        RoundedTextField(controller: priceController, prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600)), keyboardType: TextInputType.number, textInputAction: TextInputAction.next),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const FormLabel('Qty (Optional)'), const SizedBox(height: 6),
                        RoundedTextField(controller: qtyController, keyboardType: TextInputType.number, hintText: '1', textInputAction: TextInputAction.done),
                      ])),
                    ]),
                  ],
                  const SizedBox(height: 16),

                  if (!isCapital) 
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text("Status: ${isPaid ? 'Paid' : 'Pending'}", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text(isPaid ? "Transaction completed." : (isIncome ? "Waiting for payment (Credit)." : "To be paid later (Debt)."), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: isPaid,
                      onChanged: (val) => setState(() => isPaid = val ?? true),
                    ),
                  if (!isCapital) const SizedBox(height: 10),

                  if (!isCapital) ...[
                    FormLabel(isIncome ? "Customer Type" : "Payee Type"),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedContactType,
                          isExpanded: true,
                          hint: const Text("Select Type", style: TextStyle(color: AppColors.textSecondary)),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          borderRadius: BorderRadius.circular(14),
                          items: displayContactTypes.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                          onChanged: (newValue) => setState(() => _selectedContactType = newValue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const FormLabel('Category'), 
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: category, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded), borderRadius: BorderRadius.circular(14), items: displayCategories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (newValue) => setState(() => category = newValue!)))), 
                  const SizedBox(height: 16),
                  
                  const FormLabel('Notes (Optional)'), 
                  const SizedBox(height: 6), 
                  RoundedTextField(controller: notesController, hintText: 'Add details...', maxLines: 3), 
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleUpdateExpense,
                      icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                      label: Text(isLoading ? "Updating..." : "Update Record", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
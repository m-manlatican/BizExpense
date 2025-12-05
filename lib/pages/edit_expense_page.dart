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
  late TextEditingController amountController;
  late TextEditingController notesController;
  late String category;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.expense.title);
    amountController = TextEditingController(text: widget.expense.amount.toString());
    notesController = TextEditingController(text: widget.expense.notes);
    category = widget.expense.category;
    
    // Safety check: ensure current category exists in the list, if not add it locally or handle it
    if (!Expense.categories.contains(category)) {
      // If it's a legacy category not in our new list, we just keep it as is for the dropdown value
      // But typically we'd want to map it to 'Other'. For now, we assume it's valid or we add it to the displayed list.
    }
  }

  void _handleUpdateExpense() async {
    if (nameController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Amount are required.')));
      return;
    }

    final now = DateTime.now(); 
    // 🔥 USE SHARED HELPER
    final categoryDetails = Expense.getCategoryDetails(category);

    final updatedExpense = Expense(
      id: widget.expense.id, 
      title: nameController.text.trim(),
      amount: double.tryParse(amountController.text) ?? 0.0,
      category: category,
      dateLabel: "${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}",
      date: Timestamp.fromDate(now),
      notes: notesController.text.trim(),
      iconCodePoint: (categoryDetails['icon'] as IconData).codePoint,
      iconColorValue: (categoryDetails['color'] as Color).value, 
    );

    await _firestoreService.updateExpense(updatedExpense);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construct list ensuring current category is included if somehow missing
    final List<String> displayCategories = List.from(Expense.categories);
    if (!displayCategories.contains(category)) {
      displayCategories.add(category);
    }

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
                const Expanded(child: Center(child: Text("Edit Expense", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)))),
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
                  const FormLabel('Expense Name'),
                  const SizedBox(height: 6),
                  RoundedTextField(controller: nameController, hintText: 'e.g. Office Supplies'),
                  const SizedBox(height: 16),
                  const FormLabel('Amount'),
                  const SizedBox(height: 6),
                  RoundedTextField(controller: amountController, prefix: const Text('₱', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), keyboardType: const TextInputType.numberWithOptions(decimal: true), hintText: '0.00'),
                  const SizedBox(height: 16),
                  const FormLabel('Category'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        borderRadius: BorderRadius.circular(14),
                        // 🔥 USE SHARED CATEGORIES
                        items: displayCategories.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                        onChanged: (newValue) => setState(() => category = newValue!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FormLabel('Notes (Optional)'),
                  const SizedBox(height: 6),
                  RoundedTextField(controller: notesController, hintText: 'Add details...', maxLines: 3),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleUpdateExpense,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Update Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
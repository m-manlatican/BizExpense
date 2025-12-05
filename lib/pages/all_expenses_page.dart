import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/all_expenses_listview.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/pages/expense_history_page.dart'; // Import History Page
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:expense_tracker_3_0/widgets/expense_filter_modal.dart';
import 'package:flutter/material.dart';

class AllExpensesPage extends StatefulWidget {
  final VoidCallback? onBackTap;
  const AllExpensesPage({super.key, this.onBackTap});

  @override
  AllExpensesPageState createState() => AllExpensesPageState();
}

class AllExpensesPageState extends State<AllExpensesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _selectedCategories = [];
  SortOption _currentSort = SortOption.newest;
  final List<String> _allCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'];

  void _editExpense(Expense expense) async {
    await Navigator.pushNamed(context, '/edit_expense', arguments: expense);
  }

  void _deleteExpense(Expense expense) async {
    // Soft delete (moves to history)
    await _firestoreService.deleteExpense(expense.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Expense moved to History"),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFilterModal() async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExpenseFilterModal(
        allCategories: _allCategories,
        currentCategories: _selectedCategories,
        currentSort: _currentSort,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategories = result.selectedCategories;
        _currentSort = result.sortOption;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => widget.onBackTap != null ? widget.onBackTap!() : Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const Text('All Expenses', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                
                Row(
                  children: [
                    // 🔥 NEW: History Button
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseHistoryPage())),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.history, color: Colors.white, size: 20),
                      ),
                    ),
                    // Filter Button
                    InkWell(
                      onTap: _openFilterModal,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_selectedCategories.isNotEmpty || _currentSort != SortOption.newest)
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.filter_list_rounded, 
                          color: (_selectedCategories.isNotEmpty || _currentSort != SortOption.newest)
                              ? AppColors.primary 
                              : Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: StreamBuilder<List<Expense>>(
                stream: _firestoreService.getExpensesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No expenses yet.'));
                  }

                  // 🔥 FILTER: Only show active expenses
                  List<Expense> expenses = snapshot.data!.where((e) => !e.isDeleted).toList();

                  // Apply Category Filter
                  if (_selectedCategories.isNotEmpty) {
                    expenses = expenses.where((e) => _selectedCategories.contains(e.category)).toList();
                  }

                  // Apply Sort
                  expenses.sort((a, b) {
                    switch (_currentSort) {
                      case SortOption.newest: return b.date.compareTo(a.date);
                      case SortOption.oldest: return a.date.compareTo(b.date);
                      case SortOption.highestAmount: return b.amount.compareTo(a.amount);
                      case SortOption.lowestAmount: return a.amount.compareTo(b.amount);
                    }
                  });

                  if (expenses.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text('No active expenses found.'),
                      ],
                    );
                  }
                  return AllExpensesListView(expenses: expenses, onEdit: _editExpense, onDelete: _deleteExpense);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
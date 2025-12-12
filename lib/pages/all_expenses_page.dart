import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/all_expenses_listview.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/pages/expense_history_page.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:expense_tracker_3_0/widgets/expense_filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  final List<String> _allCategories = [
    ...Expense.expenseCategories,
    ...Expense.incomeCategories,
    ...Expense.capitalCategories
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowSwipeHint();
  }

  Future<void> _checkAndShowSwipeHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasDismissedHint = prefs.getBool('dismissed_swipe_hint') ?? false;
      if (hasDismissedHint) return;

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      _showSwipeHint(prefs);
    } catch (e) {
      debugPrint("Shared Preferences Error: $e");
    }
  }

  void _showSwipeHint(SharedPreferences prefs) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.swipe_right, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tip: Swipe right on an item to move it to History.",
                style: TextStyle(
                  color: AppColors.textPrimary, 
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6), 
        action: SnackBarAction(
          label: "Don't show again",
          textColor: AppColors.primary,
          onPressed: () async {
            await prefs.setBool('dismissed_swipe_hint', true);
            if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _editExpense(Expense expense) async {
    await Navigator.pushNamed(context, '/edit_expense', arguments: expense);
  }

  void _handleMarkAsPaid(Expense expense) async {
    await _firestoreService.markAsPaid(expense.id);
    
    if (!mounted) return;
    String text = expense.isIncome ? "Marked as Received" : "Marked as Paid";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text), 
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      )
    );
  }

  void _deleteExpense(Expense expense) async {
    await _firestoreService.deleteExpense(expense.id);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item moved to History"),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: "Undo",
          textColor: AppColors.secondary,
          onPressed: () async {
            await _firestoreService.restoreExpense(expense.id);
          },
        ),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 0),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                      
                      const Text(
                        'Expenses & Income', 
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)
                      ),
                      
                      Row(
                        children: [
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
                  
                  const SizedBox(height: 16),

                  const TabBar(
                    indicatorColor: AppColors.secondary,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: "Expenses"),
                      Tab(text: "Income"),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: _firestoreService.getExpensesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No transactions yet.'));
                  }

                  List<Expense> allTransactions = snapshot.data!.where((e) => !e.isDeleted).toList();

                  allTransactions.sort((a, b) {
                    switch (_currentSort) {
                      case SortOption.newest: return b.date.compareTo(a.date);
                      case SortOption.oldest: return a.date.compareTo(b.date);
                      case SortOption.highestAmount: return b.amount.compareTo(a.amount);
                      case SortOption.lowestAmount: return a.amount.compareTo(b.amount);
                    }
                  });

                  if (_selectedCategories.isNotEmpty) {
                    allTransactions = allTransactions.where((e) => _selectedCategories.contains(e.category)).toList();
                  }

                  final expenseList = allTransactions.where((e) => !e.isIncome && !e.isCapital).toList();
                  final incomeList = allTransactions.where((e) => e.isIncome || e.isCapital).toList();

                  return TabBarView(
                    children: [
                      // Tab 1: Expenses List
                      AllExpensesListView(
                        expenses: expenseList,
                        onEdit: _editExpense,
                        onDelete: _deleteExpense,
                        onMarkAsPaid: _handleMarkAsPaid,
                        // 🔥 CUSTOM MESSAGE FOR EXPENSES
                        emptyMessage: "No expenses yet",
                      ),
                      
                      // Tab 2: Income List
                      AllExpensesListView(
                        expenses: incomeList,
                        onEdit: _editExpense,
                        onDelete: _deleteExpense,
                        onMarkAsPaid: _handleMarkAsPaid,
                        // 🔥 CUSTOM MESSAGE FOR INCOME
                        emptyMessage: "No income yet",
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/available_budget_card.dart';
import 'package:expense_tracker_3_0/cards/spending_overview_card.dart';
import 'package:expense_tracker_3_0/cards/total_budget_card.dart';
import 'package:expense_tracker_3_0/cards/total_spent_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/pages/all_expenses_page.dart';
import 'package:expense_tracker_3_0/pages/reports_page.dart';
import 'package:expense_tracker_3_0/services/auth_service.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:expense_tracker_3_0/widgets/head_clipper.dart';
import 'package:expense_tracker_3_0/widgets/header_title.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Map<String, dynamic> _getChartData(List<Expense> expenses) {
    List<double> values = [];
    List<String> dates = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime target = now.subtract(Duration(days: i));
      double dailySum = expenses.where((e) {
        DateTime eDate = e.date.toDate();
        return eDate.year == target.year && eDate.month == target.month && eDate.day == target.day;
      }).fold(0.0, (sum, item) => sum + item.amount);
      values.add(dailySum);
      dates.add("${target.month}/${target.day}");
    }
    return {'values': values, 'dates': dates};
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _updateBudget(double newBudget) => _firestoreService.updateUserBudget(newBudget);

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sign Out", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text("Are you sure?", style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text("Sign Out")
          ),
        ],
      ),
    );
    if (confirm == true) await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _firestoreService.getUserBudgetStream(),
      builder: (context, budgetSnapshot) {
        
        // 🔥 FIX 1: Loading State for Budget
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final double currentBudget = budgetSnapshot.data ?? 0.00;

        final dashboardTab = StreamBuilder<List<Expense>>(
          stream: _firestoreService.getExpensesStream(),
          builder: (context, expenseSnapshot) {
            
            // 🔥 FIX 2: Loading State for Expenses
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            double totalSpent = 0.0;
            List<double> chartValues = List.filled(7, 0.0);
            List<String> chartDates = List.filled(7, '-');

            if (expenseSnapshot.hasData) {
              final expenses = expenseSnapshot.data!; 
              // 🔥 LOGIC RESTORED: Uses ALL expenses (even deleted ones) for Total Spent
              totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
              
              final chartData = _getChartData(expenses);
              chartValues = chartData['values'];
              chartDates = chartData['dates'];
            }

            return _DashboardContent(
              totalBudget: currentBudget,
              totalSpent: totalSpent,
              chartValues: chartValues,
              chartDates: chartDates,
              onBudgetChanged: _updateBudget,
              onSignOut: _signOut,
            );
          },
        );

        final List<Widget> pages = [
          dashboardTab,
          AllExpensesPage(onBackTap: () => _onItemTapped(0)),
          ReportsPage(totalBudget: currentBudget, onBackTap: () => _onItemTapped(0)),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Reports'),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            heroTag: 'fab',
            onPressed: () => Navigator.pushNamed(context, '/add_expense'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      }
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final List<double> chartValues;
  final List<String> chartDates;
  final Function(double) onBudgetChanged;
  final VoidCallback onSignOut;

  const _DashboardContent({
    required this.totalBudget,
    required this.totalSpent,
    required this.chartValues,
    required this.chartDates,
    required this.onBudgetChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final double availableBalance = totalBudget - totalSpent;
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: Align(alignment: Alignment.topCenter, child: ClipPath(clipper: HeaderClipper(), child: Container(height: 260, color: AppColors.primary)))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                HeaderTitle(onSignOut: onSignOut),
                const SizedBox(height: 20),
                TotalBudgetCard(currentBudget: totalBudget, onBudgetChanged: onBudgetChanged),
                const SizedBox(height: 12),
                TotalSpentCard(spentAmount: totalSpent, totalBudget: totalBudget),
                const SizedBox(height: 12),
                AvailableBudgetCard(balance: availableBalance),
                const SizedBox(height: 16),
                SpendingOverviewCard(spendingPoints: chartValues, dateLabels: chartDates),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
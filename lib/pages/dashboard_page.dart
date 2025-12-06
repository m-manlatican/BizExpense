import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/spending_overview_card.dart';
import 'package:expense_tracker_3_0/cards/total_budget_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/pages/all_expenses_page.dart';
import 'package:expense_tracker_3_0/pages/reports_page.dart';
import 'package:expense_tracker_3_0/services/auth_service.dart';
import 'package:expense_tracker_3_0/services/firestore_service.dart';
import 'package:expense_tracker_3_0/widgets/head_clipper.dart';
import 'package:expense_tracker_3_0/widgets/header_title.dart';
import 'package:expense_tracker_3_0/widgets/skeleton_loader.dart';
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

  // Streams
  late Stream<List<Expense>> _expensesStream;
  late Stream<double> _budgetStream;

  @override
  void initState() {
    super.initState();
    _expensesStream = _firestoreService.getExpensesStream();
    _budgetStream = _firestoreService.getUserBudgetStream();
  }

  // Calculate chart data (Expenses Only)
  Map<String, dynamic> _getChartData(List<Expense> expenses) {
    List<double> values = [];
    List<String> dates = [];
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime target = now.subtract(Duration(days: i));
      
      double dailySum = expenses.where((e) {
        DateTime eDate = e.date.toDate();
        return eDate.year == target.year && 
               eDate.month == target.month && 
               eDate.day == target.day;
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
        content: const Text("Are you sure you want to log out?", style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancel")
          ),
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

  // Skeleton Loading
  Widget _buildLoadingDashboard() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter, 
              child: ClipPath(
                clipper: HeaderClipper(), 
                child: Container(height: 260, color: AppColors.primary)
              )
            )
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 60), 
                const SkeletonLoader(height: 80, width: double.infinity),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: SkeletonLoader(height: 100, width: double.infinity)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonLoader(height: 100, width: double.infinity)),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonLoader(height: 80, width: double.infinity),
                const SizedBox(height: 16),
                const SkeletonLoader(height: 200, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _budgetStream,
      builder: (context, budgetSnapshot) {
        
        // Wait for Capital
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(backgroundColor: AppColors.background, body: _buildLoadingDashboard());
        }

        final double currentCapital = budgetSnapshot.data ?? 0.00;

        // 🔥 DEFINING THE DASHBOARD TAB WIDGET (With Data)
        final dashboardTab = StreamBuilder<List<Expense>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingDashboard();
            }

            double totalExpenses = 0.0;
            double totalIncome = 0.0;
            
            // Pending amounts
            double pendingIncome = 0.0;
            double pendingExpense = 0.0;

            List<double> chartValues = List.filled(7, 0.0);
            List<String> chartDates = List.filled(7, '-');

            if (expenseSnapshot.hasData) {
              final allTransactions = expenseSnapshot.data!.where((e) => !e.isDeleted).toList();
              
              // 🔥 BUSINESS MATH:

              // 1. Income (Sales) - Only Paid
              totalIncome = allTransactions
                  .where((e) => e.isIncome && e.isPaid)
                  .fold(0.0, (sum, item) => sum + item.amount);
              
              // 2. Expenses - Only Paid
              totalExpenses = allTransactions
                  .where((e) => !e.isIncome && !e.isCapital && e.isPaid)
                  .fold(0.0, (sum, item) => sum + item.amount);

              // 3. Pending
              pendingIncome = allTransactions
                  .where((e) => e.isIncome && !e.isPaid)
                  .fold(0.0, (sum, item) => sum + item.amount);

              pendingExpense = allTransactions
                  .where((e) => !e.isIncome && !e.isCapital && !e.isPaid)
                  .fold(0.0, (sum, item) => sum + item.amount);
              
              // Chart data (Expenses trend)
              final expenseTransactions = allTransactions.where((e) => !e.isIncome && !e.isCapital).toList();
              final chartData = _getChartData(expenseTransactions);
              chartValues = chartData['values'];
              chartDates = chartData['dates'];
            }

            return _DashboardContent(
              manualCapital: currentCapital,
              totalIncome: totalIncome,
              totalExpenses: totalExpenses,
              pendingIncome: pendingIncome,
              pendingExpense: pendingExpense,
              chartValues: chartValues,
              chartDates: chartDates,
              onUpdateCapital: _updateBudget,
              onSignOut: _signOut,
            );
          },
        );

        // 🔥 LIST OF PAGES: NO PLACEHOLDERS
        final List<Widget> pages = [
          dashboardTab, // 0: Actual Dashboard
          AllExpensesPage(onBackTap: () => _onItemTapped(0)), // 1: Records
          ReportsPage(onBackTap: () => _onItemTapped(0)), // 2: Reports
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Records'),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Reports'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            elevation: 15,
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            heroTag: 'add_expense_btn',
            onPressed: () => Navigator.pushNamed(context, '/add_expense'),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      }
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final double manualCapital;
  final double totalIncome;
  final double totalExpenses;
  final double pendingIncome;
  final double pendingExpense;
  final List<double> chartValues;
  final List<String> chartDates;
  final Function(double) onUpdateCapital;
  final VoidCallback onSignOut;

  const _DashboardContent({
    required this.manualCapital,
    required this.totalIncome,
    required this.totalExpenses,
    required this.pendingIncome,
    required this.pendingExpense,
    required this.chartValues,
    required this.chartDates,
    required this.onUpdateCapital,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    // Cash on Hand = Capital + Sales - Expenses
    final double cashOnHand = (manualCapital + totalIncome) - totalExpenses;
    final double netProfit = totalIncome - totalExpenses;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: HeaderClipper(),
                child: Container(height: 260, color: AppColors.primary),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                HeaderTitle(onSignOut: onSignOut), 
                const SizedBox(height: 20),
                
                // 1. CAPITAL
                TotalBudgetCard(
                  currentBudget: manualCapital, 
                  onBudgetChanged: onUpdateCapital,
                ),

                const SizedBox(height: 12),
                
                // 2. PROFIT & SALES
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("Net Profit", netProfit, netProfit >= 0 ? AppColors.primary : AppColors.expense),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard("Total Sales", totalIncome, AppColors.success),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                
                // 3. EXPENSES
                _buildStatCard("Total Expenses", totalExpenses, AppColors.expense, fullWidth: true),
                
                const SizedBox(height: 12),

                // 4. PENDING / ACCOUNTS (Conditional)
                if (pendingIncome > 0 || pendingExpense > 0) ...[
                  Row(
                    children: [
                      if (pendingIncome > 0) 
                        Expanded(child: _buildStatCard("To Collect", pendingIncome, Colors.orange)),
                      if (pendingIncome > 0 && pendingExpense > 0) 
                        const SizedBox(width: 12),
                      if (pendingExpense > 0)
                        Expanded(child: _buildStatCard("To Pay", pendingExpense, Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // 5. CASH ON HAND
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Cash on Hand", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          Text(
                            "₱${cashOnHand.toStringAsFixed(2)}", 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                          ),
                        ],
                      )
                    ],
                  ),
                ),

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

  Widget _buildStatCard(String title, double amount, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            "₱${amount.toStringAsFixed(2)}", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }
}
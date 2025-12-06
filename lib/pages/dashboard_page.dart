import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/cards/low_stock_card.dart'; // 🔥 Import
import 'package:expense_tracker_3_0/cards/spending_overview_card.dart';
import 'package:expense_tracker_3_0/cards/total_budget_card.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/models/inventory_model.dart'; // 🔥 Import
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
  late Stream<String> _userNameStream;
  late Stream<List<InventoryItem>> _lowStockStream; // 🔥 Low Stock Stream

  // Chart State
  ChartTimeRange _selectedChartRange = ChartTimeRange.week;

  @override
  void initState() {
    super.initState();
    _expensesStream = _firestoreService.getExpensesStream();
    _budgetStream = _firestoreService.getUserBudgetStream();
    _userNameStream = _firestoreService.getUserName();
    _lowStockStream = _firestoreService.getLowStockStream(); // 🔥 Init
  }

  // ... [Chart Data Logic - Same as before] ...
  Map<String, dynamic> _getChartData(List<Expense> expenses) {
    List<double> values = [];
    List<String> dates = [];
    DateTime now = DateTime.now();

    if (_selectedChartRange == ChartTimeRange.day) {
      for (int i = 0; i < 24; i++) {
        double hourlySum = expenses.where((e) {
          DateTime eDate = e.date.toDate();
          return e.isIncome && eDate.year == now.year && eDate.month == now.month && eDate.day == now.day && eDate.hour == i;
        }).fold(0.0, (sum, item) => sum + item.amount);
        values.add(hourlySum);
        if (i % 4 == 0) {
          int hour = i == 0 ? 12 : (i > 12 ? i - 12 : i);
          String ampm = i < 12 ? "AM" : "PM";
          dates.add("$hour $ampm");
        } else { dates.add(""); }
      }
    } else if (_selectedChartRange == ChartTimeRange.week) {
      for (int i = 6; i >= 0; i--) {
        DateTime target = now.subtract(Duration(days: i));
        double dailySum = expenses.where((e) {
          DateTime eDate = e.date.toDate();
          return e.isIncome && eDate.year == target.year && eDate.month == target.month && eDate.day == target.day;
        }).fold(0.0, (sum, item) => sum + item.amount);
        values.add(dailySum);
        dates.add("${target.month}/${target.day}");
      }
    } else {
      for (int i = 29; i >= 0; i--) {
        DateTime target = now.subtract(Duration(days: i));
        double dailySum = expenses.where((e) {
          DateTime eDate = e.date.toDate();
          return e.isIncome && eDate.year == target.year && eDate.month == target.month && eDate.day == target.day;
        }).fold(0.0, (sum, item) => sum + item.amount);
        values.add(dailySum);
        if (i % 5 == 0) { dates.add("${target.month}/${target.day}"); } else { dates.add(""); }
      }
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense), child: const Text("Sign Out")),
        ],
      ),
    );
    if (confirm == true) await _authService.signOut();
  }

  Widget _buildLoadingDashboard() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: Align(alignment: Alignment.topCenter, child: ClipPath(clipper: HeaderClipper(), child: Container(height: 260, color: AppColors.primary)))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 60), 
                const SkeletonLoader(height: 80, width: double.infinity),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: SkeletonLoader(height: 100, width: double.infinity)), SizedBox(width: 12), Expanded(child: SkeletonLoader(height: 100, width: double.infinity))]),
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
        if (budgetSnapshot.connectionState == ConnectionState.waiting) return Scaffold(backgroundColor: AppColors.background, body: _buildLoadingDashboard());
        final double manualCapital = budgetSnapshot.data ?? 0.00;

        return StreamBuilder<String>(
          stream: _userNameStream,
          builder: (context, nameSnapshot) {
            final String userName = nameSnapshot.data ?? "User";

            return StreamBuilder<List<Expense>>(
              stream: _expensesStream,
              builder: (context, expenseSnapshot) {
                if (expenseSnapshot.connectionState == ConnectionState.waiting) return _buildLoadingDashboard();

                // 🔥 Low Stock Stream
                return StreamBuilder<List<InventoryItem>>(
                  stream: _lowStockStream,
                  builder: (context, stockSnapshot) {
                    final lowStockItems = stockSnapshot.data ?? [];

                    double totalExpenses = 0.0;
                    double totalIncome = 0.0;
                    double pendingIncome = 0.0;
                    double pendingExpense = 0.0;
                    List<double> chartValues = [];
                    List<String> chartDates = [];

                    if (expenseSnapshot.hasData) {
                      final all = expenseSnapshot.data!.where((e) => !e.isDeleted).toList();
                      totalIncome = all.where((e) => e.isIncome && e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
                      totalExpenses = all.where((e) => !e.isIncome && !e.isCapital && e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
                      pendingIncome = all.where((e) => e.isIncome && !e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
                      pendingExpense = all.where((e) => !e.isIncome && !e.isCapital && !e.isPaid).fold(0.0, (sum, item) => sum + item.amount);
                      final chartData = _getChartData(all);
                      chartValues = chartData['values'];
                      chartDates = chartData['dates'];
                    }

                    final List<Widget> pages = [
                      _DashboardContent(
                        manualCapital: manualCapital,
                        userName: userName,
                        lowStockItems: lowStockItems, // 🔥 Pass List
                        totalIncome: totalIncome,
                        totalExpenses: totalExpenses,
                        pendingIncome: pendingIncome,
                        pendingExpense: pendingExpense,
                        chartValues: chartValues,
                        chartDates: chartDates,
                        onUpdateCapital: _updateBudget,
                        onSignOut: _signOut,
                        selectedRange: _selectedChartRange,
                        onRangeChanged: (range) => setState(() => _selectedChartRange = range),
                      ),
                      AllExpensesPage(onBackTap: () => _onItemTapped(0)),
                      ReportsPage(onBackTap: () => _onItemTapped(0)),
                    ];

                    return Scaffold(
                      backgroundColor: AppColors.background,
                      body: pages[_selectedIndex],
                      bottomNavigationBar: BottomNavigationBar(
                        items: const [
                          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Records'),
                          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Reports'),
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
              },
            );
          }
        );
      }
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final double manualCapital;
  final String userName;
  final List<InventoryItem> lowStockItems; // 🔥 NEW PROP
  final double totalIncome;
  final double totalExpenses;
  final double pendingIncome;
  final double pendingExpense;
  final List<double> chartValues;
  final List<String> chartDates;
  final Function(double) onUpdateCapital;
  final VoidCallback onSignOut;
  final ChartTimeRange selectedRange;
  final ValueChanged<ChartTimeRange> onRangeChanged;

  const _DashboardContent({
    required this.manualCapital,
    required this.userName,
    required this.lowStockItems, // 🔥
    required this.totalIncome,
    required this.totalExpenses,
    required this.pendingIncome,
    required this.pendingExpense,
    required this.chartValues,
    required this.chartDates,
    required this.onUpdateCapital,
    required this.onSignOut,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double cashOnHand = (manualCapital + totalIncome) - totalExpenses;
    final double netProfit = totalIncome - totalExpenses;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: Align(alignment: Alignment.topCenter, child: ClipPath(clipper: HeaderClipper(), child: Container(height: 260, color: AppColors.primary)))),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                HeaderTitle(onSignOut: onSignOut, userName: userName), 
                const SizedBox(height: 20),

                // 🔥 1. LOW STOCK ALERT (Top Priority)
                if (lowStockItems.isNotEmpty) ...[
                  LowStockCard(items: lowStockItems),
                  const SizedBox(height: 16),
                ],
                
                // 2. CAPITAL
                TotalBudgetCard(currentBudget: manualCapital, onBudgetChanged: onUpdateCapital),
                const SizedBox(height: 12),
                
                // 3. PROFIT & SALES
                Row(children: [
                  Expanded(child: _buildStatCard("Net Profit", netProfit, netProfit >= 0 ? AppColors.success : AppColors.expense)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Total Sales", totalIncome, AppColors.success)),
                ]),
                const SizedBox(height: 12),
                
                // 4. EXPENSES
                _buildStatCard("Total Expenses", totalExpenses, AppColors.expense, fullWidth: true),
                const SizedBox(height: 12),

                // 5. PENDING ACCOUNTS
                if (pendingIncome > 0 || pendingExpense > 0) ...[
                   Row(children: [
                      if (pendingIncome > 0) Expanded(child: _buildStatCard("To Collect", pendingIncome, Colors.orange, isSmall: true)),
                      if (pendingIncome > 0 && pendingExpense > 0) const SizedBox(width: 12),
                      if (pendingExpense > 0) Expanded(child: _buildStatCard("To Pay", pendingExpense, Colors.redAccent, isSmall: true)),
                   ]),
                   const SizedBox(height: 12),
                ],

                // 6. CASH ON HAND
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.secondary.withOpacity(0.5))),
                  child: Row(children: [
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Cash on Hand", style: TextStyle(fontSize: 12, color: AppColors.textPrimary)), Text("₱${cashOnHand.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))])
                  ]),
                ),

                const SizedBox(height: 16),
                
                // 7. CHART
                SpendingOverviewCard(
                  spendingPoints: chartValues, 
                  dateLabels: chartDates,
                  selectedRange: selectedRange,
                  onRangeChanged: onRangeChanged,
                ),
                
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color, {bool fullWidth = false, bool isSmall = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 16 : 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 6), Text("₱${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.w800, color: color))]),
    );
  }
}
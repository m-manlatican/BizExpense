import 'package:expense_tracker_3_0/cards/available_budget_card.dart';
import 'package:expense_tracker_3_0/cards/spending_overview_card.dart';
import 'package:expense_tracker_3_0/cards/total_spent_card.dart';
import 'package:expense_tracker_3_0/pages/add_expense_page.dart'; 
import 'package:expense_tracker_3_0/pages/all_expenses_page.dart'; 
import 'package:expense_tracker_3_0/widgets/head_clipper.dart';
import 'package:expense_tracker_3_0/widgets/header_title.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _primaryGreen = Color(0xFF0AA06E);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0; 
  
  // 1. Declare _widgetOptions without initialization
  late final List<Widget> _widgetOptions; 

  @override
  void initState() {
    super.initState();
    // 2. Initialize _widgetOptions here, where _goToExpensesTab is available
    _widgetOptions = <Widget>[
      // Pass the function to _DashboardContent
      _DashboardContent(onViewAllExpenses: _goToExpensesTab),     // Index 0: Home Dashboard 
      const AllExpensesPage(), // Index 1: All Expenses List
      const Center(child: Text('Reports Page Content', style: TextStyle(fontSize: 24, color: _primaryGreen))), // Index 2: Reports
    ];
  }

  void _goToExpensesTab() {
    _onItemTapped(1);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), 

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 10,
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C665),
        heroTag: 'add_expense_btn', 
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpensePage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback onViewAllExpenses; 

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // FIX: Use const on the key parameter to satisfy the Dart analyzer
  const _DashboardContent({required this.onViewAllExpenses});
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 260,
                  color: _primaryGreen,
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderTitle(onSignOut: _signOut), 
                const SizedBox(height: 20),
                const TotalSpentCard(),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                AvailableBudgetCard(),
                const SizedBox(height: 16),
                SpendingOverviewCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:expense_tracker_3_0/cards/all_expenses_listview.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/pages/edit_expense_page.dart';
import 'package:flutter/material.dart';
import '../firestore_functions.dart'; 

class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage({super.key});

  @override
  AllExpensesPageState createState() => AllExpensesPageState();
}

class AllExpensesPageState extends State<AllExpensesPage> {
  
  void _editExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditExpensePage(expense: expense)),
    );
  }

  void _deleteExpense(Expense expense) async {
    await deleteExpense(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    // Light gray background similar to the Dashboard body
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), 
      appBar: AppBar(
        // THEME CHANGE: Dashboard Green
        backgroundColor: const Color(0xFF00B383), 
        elevation: 0,
        title: const Text(
          'All Expenses', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () {
              // Add filter functionality here
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: StreamBuilder<List<Expense>>(
          stream: getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00B383)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No expenses yet.'));
            }

            return AllExpensesListView(
              expenses: snapshot.data!,
              onEdit: _editExpense,
              onDelete: _deleteExpense,
            );
          },
        ),
      ),
    );
  }
}
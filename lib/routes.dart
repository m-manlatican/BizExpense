import 'package:flutter/material.dart';
import 'package:expense_tracker_3_0/auth_gate.dart';
import 'package:expense_tracker_3_0/pages/dashboard_page.dart';
import 'package:expense_tracker_3_0/pages/log_in_page.dart';
import 'package:expense_tracker_3_0/pages/register_page.dart';
import 'package:expense_tracker_3_0/pages/add_expense_page.dart';
import 'package:expense_tracker_3_0/pages/edit_expense_page.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthGate());
        
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
        
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
        
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
        
      case '/add_expense':
        return MaterialPageRoute(builder: (_) => const AddExpensePage());
        
      case '/edit_expense':
        // Validation of correct data type
        if (args is Expense) {
          return MaterialPageRoute(
            builder: (_) => EditExpensePage(expense: args),
          );
        }
        // If args is not of the correct type, return an error page.
        return _errorRoute();
        
      default:
        // If there is no such named route in the switch statement
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('ERROR: Route not found or Invalid Arguments'),
        ),
      );
    });
  }
}
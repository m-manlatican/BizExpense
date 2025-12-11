import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String dateLabel;
  final Timestamp date;
  final String notes;
  final int iconCodePoint; 
  final int iconColorValue; 
  final bool isDeleted;
  final bool isIncome;
  final bool isCapital;
  final int? quantity;
  final bool isPaid; 
  final String contactName; 

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateLabel,
    required this.date,
    required this.notes,
    required this.iconCodePoint,
    required this.iconColorValue,
    this.isDeleted = false,
    this.isIncome = false,
    this.isCapital = false,
    this.quantity,
    this.isPaid = true,
    this.contactName = '', 
  });

  static const List<String> expenseCategories = [
    'Inventory', 'Rent', 'Utilities', 'Labor', 'Marketing', 'Equipment', 'Tax', 'Other'
  ];
  
  static const List<String> incomeCategories = [
    'Product Sales', 'Service Fee', 'Other Income'
  ];

  static const List<String> capitalCategories = [
    'Initial Capital', 'Additional Investment', 'Loan', 'Grant'
  ];

  // 🔥 NEW: Standard Contact Types for Dropdown
  static const List<String> expenseContactTypes = [
    'Supplier', 'Payee', 'Vendor', 'Employee', 'Contractor', 'Other'
  ];

  static const List<String> incomeContactTypes = [
    'Customer', 'Client', 'Payer', 'Other'
  ];

  static Map<String, dynamic> getCategoryDetails(String category) {
    switch (category) {
      // EXPENSES
      case 'Inventory': return {'icon': Icons.inventory_2, 'color': const Color(0xFFE76F51)}; 
      case 'Rent': return {'icon': Icons.store, 'color': const Color(0xFF264653)}; 
      case 'Utilities': return {'icon': Icons.bolt, 'color': const Color(0xFFE9C46A)}; 
      case 'Labor': return {'icon': Icons.group, 'color': const Color(0xFFF4A261)}; 
      case 'Marketing': return {'icon': Icons.campaign, 'color': const Color(0xFF8D99AE)}; 
      case 'Equipment': return {'icon': Icons.build, 'color': const Color(0xFF607D8B)};
      case 'Tax': return {'icon': Icons.account_balance, 'color': const Color(0xFF9E9E9E)};
      
      // INCOME
      case 'Product Sales': return {'icon': Icons.point_of_sale, 'color': const Color(0xFF2A9D8F)}; 
      case 'Service Fee': return {'icon': Icons.handyman, 'color': const Color(0xFFE9C46A)}; 
      case 'Other Income': return {'icon': Icons.attach_money, 'color': const Color(0xFF264653)};

      // CAPITAL
      case 'Initial Capital': return {'icon': Icons.savings, 'color': const Color(0xFF4E6AFF)}; 
      case 'Additional Investment': return {'icon': Icons.add_card, 'color': const Color(0xFF4E6AFF)};
      case 'Loan': return {'icon': Icons.credit_score, 'color': const Color(0xFF3F51B5)};
      case 'Grant': return {'icon': Icons.card_giftcard, 'color': const Color(0xFF673AB7)};
      
      default: return {'icon': Icons.grid_view, 'color': const Color(0xFF8E8E93)}; 
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'dateLabel': dateLabel,
      'date': date,
      'notes': notes,
      'iconCodePoint': iconCodePoint,
      'iconColorValue': iconColorValue,
      'isDeleted': isDeleted,
      'isIncome': isIncome,
      'isCapital': isCapital,
      'quantity': quantity,
      'isPaid': isPaid,
      'contactName': contactName,
    };
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    return Expense(
      id: id,
      title: map['title'] ?? 'Untitled',
      category: map['category'] ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dateLabel: map['dateLabel'] ?? '',
      date: map['date'] as Timestamp? ?? Timestamp.now(),
      notes: map['notes'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? Icons.error.codePoint,
      iconColorValue: map['iconColorValue'] ?? 0xFF000000,
      isDeleted: map['isDeleted'] ?? false,
      isIncome: map['isIncome'] ?? false,
      isCapital: map['isCapital'] ?? false,
      quantity: map['quantity'] as int?,
      isPaid: map['isPaid'] ?? true,
      contactName: map['contactName'] ?? '',
    );
  }

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get iconColor => Color(iconColorValue);
}
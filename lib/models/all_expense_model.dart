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
  });

  // 🔥 SRP: Single Source of Truth for Categories
  static const List<String> categories = [
    'Food', 
    'Transport', 
    'Shopping', 
    'Bills', 
    'Entertainment', 
    'Health', 
    'Software',  // Added
    'Supplies',  // Added
    'Meals',     // Added
    'Travel',    // Added
    'Other'
  ];

  // 🔥 SRP: Centralized Icon/Color Logic
  static Map<String, dynamic> getCategoryDetails(String category) {
    switch (category) {
      case 'Food': 
        return {'icon': Icons.fastfood, 'color': const Color(0xFFFF9F0A)}; 
      case 'Transport': 
        return {'icon': Icons.directions_car, 'color': const Color(0xFF0A84FF)}; 
      case 'Shopping': 
        return {'icon': Icons.shopping_bag, 'color': const Color(0xFFBF5AF2)}; 
      case 'Bills': 
        return {'icon': Icons.receipt_long, 'color': const Color(0xFFFF375F)}; 
      case 'Entertainment': 
        return {'icon': Icons.movie, 'color': const Color(0xFF5E5CE6)}; 
      case 'Health': 
        return {'icon': Icons.medical_services, 'color': const Color(0xFF32D74B)};
      // 🔥 New Categories
      case 'Software': 
        return {'icon': Icons.computer, 'color': const Color(0xFF4E6AFF)}; 
      case 'Supplies': 
        return {'icon': Icons.inventory_2, 'color': const Color(0xFF795548)}; 
      case 'Meals': 
        return {'icon': Icons.restaurant, 'color': const Color(0xFFFF5722)}; 
      case 'Travel': 
        return {'icon': Icons.flight, 'color': const Color(0xFF00BCD4)}; 
      case 'Other':
      default: 
        return {'icon': Icons.grid_view, 'color': const Color(0xFF8E8E93)}; 
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
    );
  }

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get iconColor => Color(iconColorValue);
}
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
  // 🔥 NEW: Track if deleted (Soft Delete)
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
    this.isDeleted = false, // Default to active
  });

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
      'isDeleted': isDeleted, // Save status
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
      // Load status (default false for old data)
      isDeleted: map['isDeleted'] ?? false, 
    );
  }

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get iconColor => Color(iconColorValue);
}
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final Timestamp lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.lastUpdated,
  });

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      name: map['name'] ?? 'Unknown Item',
      quantity: map['quantity'] ?? 0,
      lastUpdated: map['lastUpdated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'lastUpdated': lastUpdated,
    };
  }
}
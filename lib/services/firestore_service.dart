import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:expense_tracker_3_0/models/inventory_model.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference? get _userDoc {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId);
  }

  Stream<String> getUserName() {
    final ref = _userDoc;
    if (ref == null) return Stream.value("User");

    return ref.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('firstName') && data['firstName'] != null) {
           return data['firstName'];
        }
        if (data.containsKey('fullName') && data['fullName'] != null) {
           final String full = data['fullName'];
           if (full.isNotEmpty) return full.split(' ').first;
        }
      }
      return "User";
    });
  }

  // --- INVENTORY METHODS ---
  CollectionReference? get _inventoryCollection => _userDoc?.collection('inventory');

  Stream<List<InventoryItem>> getLowStockStream() {
    final ref = _inventoryCollection;
    if (ref == null) return Stream.value([]);
    
    // 🔥 FIX: Filter 'where' first using the raw 'doc', THEN 'map' to InventoryItem
    return ref.where('quantity', isLessThan: 10).orderBy('quantity').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             // Filter out items that are ignored
             return data['isIgnored'] != true; 
          })
          .map((doc) => InventoryItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .take(3) // Limit to 3 items after filtering
          .toList();
    });
  }

  Future<void> updateStock(String itemName, int quantityChange) async {
    final ref = _inventoryCollection;
    if (ref == null) return;
    final queryName = itemName.trim().toLowerCase();
    final snapshot = await ref.where('name', isEqualTo: queryName).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await doc.reference.update({
        'quantity': FieldValue.increment(quantityChange),
        'lastUpdated': Timestamp.now(),
        'isIgnored': false, // Un-ignore if we restock it manually
      });
    } else if (quantityChange > 0) {
      await ref.add({
        'name': queryName, 
        'quantity': quantityChange, 
        'lastUpdated': Timestamp.now(),
        'isIgnored': false,
      });
    }
  }

  // Method to ignore a stock item
  Future<void> ignoreInventoryItem(String itemId) async {
    final ref = _inventoryCollection;
    if (ref == null) return;
    await ref.doc(itemId).update({'isIgnored': true});
  }

  // --- BUDGET METHODS ---
  Stream<double> getUserBudgetStream() {
    final ref = _userDoc;
    if (ref == null) return Stream.value(0.0);
    return ref.snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return (data['totalBudget'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  Future<void> updateUserBudget(double newBudget) async {
    final ref = _userDoc;
    if (ref == null) throw Exception("User not logged in");
    await ref.set({'totalBudget': newBudget}, SetOptions(merge: true));
  }

  // --- EXPENSE METHODS ---
  Stream<List<Expense>> getExpensesStream() {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) return Stream.value([]);
    return ref.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> addExpense(Expense expense) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.add(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(expense.id).update(expense.toMap());
  }

  Future<void> markAsPaid(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).update({'isPaid': true});
  }

  Future<void> deleteExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).update({'isDeleted': true});
  }

  Future<void> restoreExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).update({'isDeleted': false});
  }

  Future<void> permanentlyDeleteExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).delete();
  }

  Future<void> clearHistory() async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    final snapshot = await ref.where('isDeleted', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
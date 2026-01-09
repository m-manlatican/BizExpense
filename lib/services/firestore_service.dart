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

  Stream<List<InventoryItem>> getAllInventoryStream() {
    final ref = _inventoryCollection;
    if (ref == null) return Stream.value([]);
    
    return ref
        .orderBy('name') 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .where((item) {
                final data = snapshot.docs.firstWhere((d) => d.id == item.id).data() as Map<String, dynamic>;
                return data['isIgnored'] != true;
              })
              .toList();
    });
  }

  Stream<List<InventoryItem>> getLowStockStream() {
    final ref = _inventoryCollection;
    if (ref == null) return Stream.value([]);
    
    return ref
        .where('quantity', isLessThan: 10)
        .where('isIgnored', isNotEqualTo: true) 
        .orderBy('quantity')
        .limit(5)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
    });
  }

  // 🔥 UPDATED: Robust updateStock with Safe Casting
  Future<void> updateStock(String itemName, int quantityChange) async {
    final ref = _inventoryCollection;
    if (ref == null) return;
    final queryName = itemName.trim(); 
    
    try {
      final snapshot = await ref.where('name', isEqualTo: queryName).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        // 🔥 SAFE CAST: Handle if Firestore stored it as a double/number
        final num currentNum = data['quantity'] as num? ?? 0;
        final int currentQty = currentNum.toInt();
        
        final newQty = currentQty + quantityChange;

        if (newQty <= 0) {
          // Delete if 0 or less
          await doc.reference.delete();
        } else {
          await doc.reference.update({
            'quantity': newQty,
            'lastUpdated': Timestamp.now(),
            'isIgnored': false,
          });
        }
      } else if (quantityChange > 0) {
        // Only create if adding
        await ref.add({
          'name': queryName, 
          'quantity': quantityChange, 
          'lastUpdated': Timestamp.now(),
          'isIgnored': false,
        });
      }
    } catch (e) {
      print("Error updating stock: $e");
      // We suppress the error so it doesn't block other operations
    }
  }

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

  // Ensures the expense is deleted even if stock update fails
  Future<void> permanentlyDeleteExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    
    try {
      final docSnapshot = await ref.doc(id).get();
      if (!docSnapshot.exists) return; 

      final expense = Expense.fromMap(docSnapshot.id, docSnapshot.data()!);

      final bool isExpense = !expense.isIncome && !expense.isCapital;
      final bool isInventoryCategory = expense.category == 'Inventory' || expense.category == 'Product';

      if (isExpense && isInventoryCategory) {
         final int qtyToRemove = expense.quantity ?? 1;
         // Try to remove stock, but don't let it crash the whole function
         await updateStock(expense.title, -qtyToRemove);
      }
    } catch (e) {
      print("Error during pre-delete logic: $e");
    }

    // ALWAYS delete the document
    await ref.doc(id).delete();
  }

  // 🔥 UPDATED: Ensures history is cleared even if stock updates fail
  Future<void> clearHistory() async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");

    final snapshot = await ref.where('isDeleted', isEqualTo: true).get();
    
    // 1. Adjust Stocks
    for (final doc in snapshot.docs) {
       try {
         final expense = Expense.fromMap(doc.id, doc.data());
         final bool isExpense = !expense.isIncome && !expense.isCapital;
         final bool isInventoryCategory = expense.category == 'Inventory' || expense.category == 'Product';

         if (isExpense && isInventoryCategory) {
           final int qty = expense.quantity ?? 1;
           await updateStock(expense.title, -qty);
         }
       } catch (e) {
         print("Error adjusting stock for history item: $e");
       }
    }

    // 2. Delete All
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
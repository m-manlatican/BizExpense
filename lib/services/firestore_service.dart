import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_3_0/models/all_expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference? get _userDoc {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId);
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
      return snapshot.docs.map((doc) {
        return Expense.fromMap(doc.id, doc.data());
      }).toList();
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

  // 🔥 SOFT DELETE: Moves to History (Updates flag only)
  Future<void> deleteExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).update({'isDeleted': true});
  }

  // 🔥 RESTORE: Moves back to Active List
  Future<void> restoreExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).update({'isDeleted': false});
  }

  // 🔥 HARD DELETE: Permanently removes from DB (Used in History Page)
  Future<void> permanentlyDeleteExpense(String id) async {
    final ref = _userDoc?.collection('expenses');
    if (ref == null) throw Exception("User not logged in");
    await ref.doc(id).delete();
  }

  // 🔥 CLEAR ALL HISTORY
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
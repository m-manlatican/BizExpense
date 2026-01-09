import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email, 
    required String password, 
    required String firstName,
    required String lastName,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );

    // Save user details to Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': Timestamp.now(),
      'totalBudget': 0.0,
    });

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
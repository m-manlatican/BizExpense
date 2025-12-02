import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    try {
      setState(() => isLoading = true);
      
      // 1. Create User in Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      // 2. Save details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': name,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      // 3. SUCCESS
      if (!mounted) return;
      Navigator.pop(context); 

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7FFF2),
      // AppBar ensures the "body" starts at the same vertical offset as other pages
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        // Back button is black to match the theme
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      // Removed "Center" so the title stays at a fixed top position
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const Text(
              "Create Account", 
              style: TextStyle(
                fontSize: 28, // Matches Login Page
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            
            // Full Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.person, color: Colors.black54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A86B), width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.email, color: Colors.black54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A86B), width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.lock, color: Colors.black54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A86B), width: 2)),
              ),
            ),
            const SizedBox(height: 40),
            
            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B), 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(), // Pill shape
                  elevation: 0,
                ),
                child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
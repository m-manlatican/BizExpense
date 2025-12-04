import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Removed unused import: register_page.dart

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    // ... (Existing login logic remains unchanged) ...
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Login failed'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7FFF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const Icon(Icons.heat_pump_rounded,size: 50,),
            const Text(
              "Welcome",
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                // ... (rest of styling) ...
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.email, color: Colors.black54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A86B), width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                // ... (rest of styling) ...
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.lock, color: Colors.black54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A86B), width: 2)),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B), 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () {
                // Use named route for register
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                "Don't have an account? Register",
                style: TextStyle(color: Color(0xFF6A5ACD)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
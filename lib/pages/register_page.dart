import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:expense_tracker_3_0/services/auth_service.dart';
import 'package:expense_tracker_3_0/widgets/form_fields.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  bool isLoading = false;

  void _clearErrors() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  Future<void> _register() async {
    _clearErrors();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    bool isValid = true;

    // Validation
    if (firstName.isEmpty) {
      setState(() => _firstNameError = "First name is required");
      isValid = false;
    }
    if (lastName.isEmpty) {
      setState(() => _lastNameError = "Last name is required");
      isValid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = "Email is required");
      isValid = false;
    } else if (!email.contains('@')) {
      setState(() => _emailError = "Invalid email format");
      isValid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = "Password is required");
      isValid = false;
    } else if (password.length < 6) {
      setState(() => _passwordError = "Password must be at least 6 characters");
      isValid = false;
    }

    if (!isValid) return;

    try {
      setState(() => isLoading = true);
      
      await _authService.register(
        email: email, 
        password: password, 
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;
      Navigator.pop(context); 

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'email-already-in-use') {
          _emailError = "This email is already registered.";
        } else if (e.code == 'invalid-email') {
          _emailError = "Invalid email address.";
        } else if (e.code == 'weak-password') {
          _passwordError = "Password is too weak.";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message ?? "Registration failed"),
            backgroundColor: AppColors.expense,
          ));
        }
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text("Start tracking your business finances today.", style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              
              // First Name & Last Name
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel("First Name"),
                        const SizedBox(height: 8),
                        RoundedTextField(
                          controller: firstNameController,
                          hintText: "John",
                          prefix: const Icon(Icons.person_outline),
                          errorText: _firstNameError,
                          onChanged: (_) => setState(() => _firstNameError = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel("Last Name"),
                        const SizedBox(height: 8),
                        RoundedTextField(
                          controller: lastNameController,
                          hintText: "Doe",
                          errorText: _lastNameError,
                          onChanged: (_) => setState(() => _lastNameError = null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              const FormLabel("Email Address"),
              const SizedBox(height: 8),
              RoundedTextField(
                controller: emailController,
                hintText: "hello@example.com",
                prefix: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 20),
              
              const FormLabel("Password"),
              const SizedBox(height: 8),
              RoundedTextField(
                controller: passwordController,
                hintText: "••••••••",
                prefix: const Icon(Icons.lock_outline),
                obscureText: true,
                errorText: _passwordError,
                onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
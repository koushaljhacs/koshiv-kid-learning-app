/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/parent_registration_screen.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Parent Registration UI — Form fields for user data collection
 * Version 1.1.0 | Updated form fields per backend API spec — Added child_name (required), child_dob, child_grade (optional), restructured layout into Parent Details and Child Details sections
 * Version 1.1.1 | Added navigation to OtpVerificationScreen on successful validation
 * 
 * Aim: Secure Parent Registration UI (Step 1) — Aligned with POST /api/v1/auth/register/init
 * Why: Collects parent_name, email, password (required), phone_number (optional)
 *      plus child_name (required), child_dob, child_grade (optional).
 *      On valid submission, navigates to OTP verification screen.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _childDobController = TextEditingController();
  final TextEditingController _childGradeController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _parentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _childNameController.dispose();
    _childDobController.dispose();
    _childGradeController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final parentName = _parentNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final childName = _childNameController.text.trim();

    if (parentName.isEmpty || email.isEmpty || password.isEmpty || childName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields: Parent Name, Email, Password, and Child Name.')),
      );
      return;
    }

    // Placeholder for actual API integration (POST /api/v1/auth/register/init)
    debugPrint('Initiating OTP Dispatch for: $email');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Parent'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Koshiv to monitor your child\'s learning progress.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Parent Details Section
              const Text(
                'Parent Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Child Details Section
              const Text(
                'Child Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childNameController,
                decoration: const InputDecoration(
                  labelText: 'Child Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.child_care),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childDobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (optional)',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childGradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade/Class (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSendOtp,
                  child: const Text('Send OTP', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
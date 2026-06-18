/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/registration_success_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.2.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Registration Success Screen — Displays child handle and PIN
 * Version 1.1.0 | Added email notification message — Informs parent to check email for credentials
 * Version 1.2.0 | Fixed Go to Login navigation — Pops to RoleSelectionScreen instead of ParentLoginScreen
 * 
 * Aim: Registration Success UI — COPPA-Compliant Credential Display
 * Why: To display the auto-generated child handle and PIN immediately after
 *      successful registration. Go to Login now correctly navigates to
 *      RoleSelectionScreen which handles both parent and student login.
 * ============================================================
 */

import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String childHandle;
  final String childPin;
  final String parentEmail;

  const RegistrationSuccessScreen({
    super.key,
    required this.childHandle,
    required this.childPin,
    required this.parentEmail,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 375).clamp(0.85, 1.05);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32 * s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 24 * s),
              Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 28 * s,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12 * s),
              Text(
                'Save these credentials for your child\'s login.\nThey will not be shown again.',
                style: TextStyle(
                  fontSize: 16 * s,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12 * s),

              // Email Notification Message
              Container(
                padding: EdgeInsets.all(12 * s),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8 * s),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.blue.shade700, size: 20 * s),
                    SizedBox(width: 8 * s),
                    Expanded(
                      child: Text(
                        'Credentials also sent to $parentEmail. Please check your inbox.',
                        style: TextStyle(
                          fontSize: 13 * s,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32 * s),

              // Child Handle
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * s),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Child Handle',
                      style: TextStyle(
                        fontSize: 14 * s,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Text(
                      childHandle,
                      style: TextStyle(
                        fontSize: 24 * s,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * s),

              // Child PIN
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * s),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Child PIN',
                      style: TextStyle(
                        fontSize: 14 * s,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Text(
                      childPin,
                      style: TextStyle(
                        fontSize: 32 * s,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40 * s),

              // Go to Login Button
              SizedBox(
                width: double.infinity,
                height: 50 * s,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.roleSelection,
                      (route) => false,
                    );
                  },
                  child: Text('Go to Login', style: TextStyle(fontSize: 16 * s)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
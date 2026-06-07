/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/role_selection_screen.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Role Selection Screen — Parent/Student login and registration entry points
 * Version 1.1.0 | Wired Login as Parent button to navigate to ParentLoginScreen via AppRoutes
 * 
 * Aim: Role Selection UI for Authentication Flow
 * Why: To enforce RBAC and COPPA data isolation from the first user interaction.
 *      Users must self-select their role before proceeding to login or registration.
 * ============================================================
 */

import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Koshiv Branding Placeholder
                const Text(
                  'Koshiv',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learning App for Kids',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 64),

                // Login as Parent Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.parentLogin);
                    },
                    child: const Text('Login as Parent'),
                  ),
                ),
                const SizedBox(height: 16),

                // Login as Student Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('Navigating to Student Login...');
                    },
                    child: const Text('Login as Student'),
                  ),
                ),
                const SizedBox(height: 24),

                // Register as Parent Button
                TextButton(
                  onPressed: () {
                    debugPrint('Navigating to Parent Registration...');
                  },
                  child: const Text('New to Koshiv? Register as Parent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
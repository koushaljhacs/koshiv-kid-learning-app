/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: core_initialization
 * File: lib/main.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Main Entry Point — Environment initialization before runApp, placeholder home screen
 * Version 1.1.0 | Updated home to RoleSelectionScreen — App now boots directly into role selection flow
 * 
 * Aim: Application Entry Point with Secure Boot and Role-Based Routing
 * Why: To ensure ApiConfig loads environment variables before any widget renders,
 *      and to direct users to role selection as the first interaction point
 *      for RBAC and COPPA compliance.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'core/config/api.config.dart';
import 'features/auth/presentation/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  runApp(const KoshivApp());
}

class KoshivApp extends StatelessWidget {
  const KoshivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koshiv Edu',
      home: const RoleSelectionScreen(),
    );
  }
}
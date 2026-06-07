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
 * Version 1.1.1 | Updated import path — Changed from api.config.dart to api_config.dart per snake_case convention
 * Version 1.2.0 | Added named routing — Replaced home with initialRoute and routes map using AppRoutes constants
 * 
 * Aim: Application Entry Point with Secure Boot and Named Routing
 * Why: To ensure ApiConfig loads environment variables before any widget renders,
 *      and to provide centralized named routing for type-safe navigation
 *      across the authentication flow.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'core/config/api_config.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/presentation/role_selection_screen.dart';
import 'features/auth/presentation/parent_login_screen.dart';

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
      initialRoute: AppRoutes.roleSelection,
      routes: {
        AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
        AppRoutes.parentLogin: (context) => const ParentLoginScreen(),
      },
    );
  }
}
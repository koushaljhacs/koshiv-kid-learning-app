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
 * Version 1.0.0 | Initial Main Entry Point — Environment initialization before runApp
 * 
 * Aim: Application Entry Point with Secure Boot
 * Why: To ensure ApiConfig loads environment variables before any widget renders.
 *      Guarantees zero hardcoded configuration at app startup.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'core/config/api.config.dart';

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
      home: Scaffold(
        body: Center(
          child: Text('Environment Initialized. Base URL Loaded.'),
        ),
      ),
    );
  }
}
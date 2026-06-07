/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: core_configuration
 * File: lib/core/config/api_config.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial API Config — Environment variable parsing and Base URL setup
 * 
 * Aim: Secure API Configuration Module
 * Why: To parse and validate environment variables from the .env file.
 *      Ensures zero hardcoding of network IP addresses or sensitive URLs.
 *      Fails fast if the base URL is missing.
 * ============================================================
 */

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('CRITICAL: API_BASE_URL is missing from environment configuration.');
    }
    return url;
  }
}
/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: core_network
 * File: lib/core/network/dio_client.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Dio Network Client — Centralized HTTP client with base config
 * 
 * Aim: Centralized HTTP Network Client
 * Why: Single source of truth for all API communication.
 *      Uses ApiConfig for base URL, sets JSON headers,
 *      and configures timeouts for production reliability.
 * ============================================================
 */

import 'package:dio/dio.dart';
import '../config/api_config.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get instance => _dio;
}
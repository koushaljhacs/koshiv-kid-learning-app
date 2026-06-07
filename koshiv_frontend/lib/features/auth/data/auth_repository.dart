/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_data
 * File: lib/features/auth/data/auth_repository.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth Repository — registerInit and registerComplete API calls
 * 
 * Aim: Auth API Data Layer
 * Why: Abstracts HTTP communication for auth endpoints.
 *      Handles POST /register/init and POST /register/complete
 *      with proper error extraction from DioException responses.
 * ============================================================
 */

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<void> registerInit(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/register/init', data: payload);
      print('Register Init Success: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Registration failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> registerComplete(String email, String otp) async {
    try {
      final response = await _dio.post('/register/complete', data: {
        'email': email,
        'otp': otp,
      });
      print('Register Complete Success: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'OTP verification failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
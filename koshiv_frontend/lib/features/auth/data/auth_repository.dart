/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_data
 * File: lib/features/auth/data/auth_repository.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.2.1
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth Repository — registerInit and registerComplete API calls
 * Version 1.0.1 | Added detailed error logging for DioException to aid debugging
 * Version 1.0.2 | Fixed endpoint paths — Added /auth prefix per backend routing
 * Version 1.1.0 | Added forgotPassword method — POST /auth/forgot-password endpoint
 * Version 1.2.0 | Added forgotPasswordVerifyOtp and forgotPasswordReset methods — Complete 3-step forgot password flow
 * Version 1.2.1 | forgotPassword now returns bool via email_dispatched flag — Frontend can determine if OTP was actually sent
 * 
 * Aim: Auth API Data Layer
 * Why: Abstracts HTTP communication for auth endpoints.
 *      Handles registration and complete 3-step password reset flows
 *      with proper error handling and response parsing.
 *      email_dispatched flag enables accurate UI flow control.
 * ============================================================
 */

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<void> registerInit(Map<String, dynamic> payload) async {
    try {
      print('Register Init Request: $payload');
      final response = await _dio.post('/auth/register/init', data: payload);
      print('Register Init Success: ${response.statusCode}');
      print('Register Init Response: ${response.data}');
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException Status Code: ${e.response?.statusCode}');
      print('DioException Response Data: ${e.response?.data}');
      print('DioException Message: ${e.message}');
      final message = e.response?.data?['error'] ?? 'Registration failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> registerComplete(String email, String otp) async {
    try {
      print('Register Complete Request: email=$email, otp=$otp');
      final response = await _dio.post('/auth/register/complete', data: {
        'email': email,
        'otp': otp,
      });
      print('Register Complete Success: ${response.statusCode}');
      print('Register Complete Response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException Status Code: ${e.response?.statusCode}');
      print('DioException Response Data: ${e.response?.data}');
      print('DioException Message: ${e.message}');
      final message = e.response?.data?['error'] ?? 'OTP verification failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  // Step 1: Request OTP for forgot password — returns true if OTP dispatched
  Future<bool> forgotPassword(String email, String phone) async {
    try {
      print('Forgot Password Request: email=$email, phone=$phone');
      final response = await _dio.post('/auth/forgot-password', data: {
        'email': email,
        'phone': phone,
      });
      print('Forgot Password Success: ${response.statusCode}');
      print('Forgot Password Response: ${response.data}');

      final emailDispatched = response.data['email_dispatched'] as bool? ?? false;
      return emailDispatched;
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException Status Code: ${e.response?.statusCode}');
      print('DioException Response Data: ${e.response?.data}');
      print('DioException Message: ${e.message}');
      final message = e.response?.data?['error'] ?? 'Failed to process request. Please try again.';
      throw Exception(message);
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Step 2: Verify OTP for forgot password
  Future<Map<String, dynamic>> forgotPasswordVerifyOtp(String email, String otp) async {
    try {
      print('Forgot Password Verify OTP Request: email=$email, otp=$otp');
      final response = await _dio.post('/auth/forgot-password/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      print('Forgot Password Verify OTP Success: ${response.statusCode}');
      print('Forgot Password Verify OTP Response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException Status Code: ${e.response?.statusCode}');
      print('DioException Response Data: ${e.response?.data}');
      print('DioException Message: ${e.message}');
      final message = e.response?.data?['error'] ?? 'OTP verification failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }

  // Step 3: Reset password with temp token
  Future<void> forgotPasswordReset(String email, String tempToken, String newPassword) async {
    try {
      print('Forgot Password Reset Request: email=$email');
      final response = await _dio.post('/auth/forgot-password/reset', data: {
        'email': email,
        'temp_token': tempToken,
        'new_password': newPassword,
      });
      print('Forgot Password Reset Success: ${response.statusCode}');
      print('Forgot Password Reset Response: ${response.data}');
    } on DioException catch (e) {
      print('DioException: ${e.type}');
      print('DioException Status Code: ${e.response?.statusCode}');
      print('DioException Response Data: ${e.response?.data}');
      print('DioException Message: ${e.message}');
      final message = e.response?.data?['error'] ?? 'Password reset failed. Please try again.';
      throw Exception(message);
    } catch (e) {
      print('Unexpected Error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }
}
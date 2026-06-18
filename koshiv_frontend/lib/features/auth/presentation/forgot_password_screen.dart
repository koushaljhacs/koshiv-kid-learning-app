/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/forgot_password_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Forgot Password Screen — Email input with reset link dispatch
 * 
 * Aim: Secure Forgot Password Screen
 * Why: To allow parents to request a password reset link via email.
 *      Validates email format before API call.
 *      Shows success confirmation or error inline.
 *      Clean professional UI matching Koshiv design system.
 * ============================================================
 */

import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => _errorText = 'Email address is required.');
      return false;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorText = 'Please enter a valid email address.');
      return false;
    }
    setState(() => _errorText = null);
    return true;
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();

    if (!_validateEmail(email)) return;

    setState(() => _isLoading = true);

    try {
      await _authRepository.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorText = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 375).clamp(0.85, 1.05);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFDE47B),
              Color(0xFFFF6B6B),
              Color(0xFF87CEEB),
              Color(0xFF4A8E9F),
              Color(0xFF90EE90),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 0),
                child: Row(
                  children: [
                    Container(
                      height: 38 * s,
                      padding: EdgeInsets.symmetric(horizontal: 14 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(20 * s),
                        border: Border.all(color: Colors.white.withAlpha(80), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 6 * s,
                            offset: Offset(0, 2 * s),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20 * s),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20 * s),
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, color: const Color(0xFF1E293B), size: 16 * s),
                              SizedBox(width: 4 * s),
                              Text('Back', style: TextStyle(fontSize: 13 * s, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 24 * s),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(24 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22 * s),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20 * s,
                              offset: Offset(0, 8 * s),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Icon
                            Container(
                              padding: EdgeInsets.all(14 * s),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E607A).withAlpha(25),
                                border: Border.all(
                                  color: const Color(0xFF1E607A).withAlpha(50),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(Icons.lock_reset_rounded, color: const Color(0xFF1E607A), size: 32 * s),
                            ),
                            SizedBox(height: 16 * s),

                            // Title
                            Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontSize: 22 * s,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Text(
                              'Enter your registered email address and we will send you a password reset link.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13 * s,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),

                            SizedBox(height: 24 * s),

                            if (_isSuccess) ...[
                              // Success State
                              Container(
                                padding: EdgeInsets.all(16 * s),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12 * s),
                                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                                    SizedBox(width: 10 * s),
                                    Expanded(
                                      child: Text(
                                        'If an account exists for this email, a password reset link has been sent.',
                                        style: TextStyle(fontSize: 13 * s, color: const Color(0xFF166534)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20 * s),
                              // Done Button
                              SizedBox(
                                width: double.infinity,
                                height: 46 * s,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E607A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 * s)),
                                  ),
                                  child: Text('Done', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ] else ...[
                              // Email Input
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                style: TextStyle(fontSize: 14 * s, color: const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'parent@example.com',
                                  errorText: _errorText,
                                  isDense: true,
                                  labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 13 * s),
                                  floatingLabelStyle: TextStyle(color: const Color(0xFF1E607A), fontWeight: FontWeight.w600),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.all(10 * s),
                                    child: Container(
                                      padding: EdgeInsets.all(6 * s),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9).withAlpha(20),
                                        borderRadius: BorderRadius.circular(8 * s),
                                      ),
                                      child: const Icon(Icons.email_outlined, color: Color(0xFF0EA5E9), size: 18),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  errorStyle: TextStyle(fontSize: 11 * s),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 15 * s),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFF1E607A), width: 1.6)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                                ),
                                onChanged: (_) {
                                  if (_errorText != null) setState(() => _errorText = null);
                                },
                              ),

                              SizedBox(height: 22 * s),

                              // Send Reset Link Button
                              Container(
                                width: double.infinity,
                                height: 46 * s,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF1E607A), Color(0xFF2B6B80)]),
                                  borderRadius: BorderRadius.circular(24 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E607A).withAlpha(80),
                                      blurRadius: 10 * s,
                                      offset: Offset(0, 4 * s),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24 * s),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24 * s),
                                    onTap: _isLoading ? null : _handleSendResetLink,
                                    child: Center(
                                      child: _isLoading
                                          ? SizedBox(height: 20 * s, width: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                          : Text('Send Reset Link', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.4)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
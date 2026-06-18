/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/forgot_password_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.1.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Forgot Password Screen — Email input with reset link dispatch
 * Version 1.1.0 | Added phone field, wired Step 1 API, navigates to OTP screen on success
 * 
 * Aim: Secure Forgot Password Screen — Step 1 of 3
 * Why: Collects email and phone, sends OTP via backend.
 *      On success navigates to existing OTP verification screen in forgot password mode.
 *      Security: Same generic message whether account exists or not.
 * ============================================================
 */

import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool isValid = true;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email address is required.');
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      isValid = false;
    } else {
      setState(() => _emailError = null);
    }

    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number is required.');
      isValid = false;
    } else if (phone.length < 10) {
      setState(() => _phoneError = 'Please enter a valid phone number.');
      isValid = false;
    } else {
      setState(() => _phoneError = null);
    }

    return isValid;
  }

  Future<void> _handleSendOtp() async {
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      await _authRepository.forgotPassword(email, phone);
      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => OtpVerificationScreen(
            email: email,
            mode: OtpMode.forgotPassword,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() => _emailError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              Color(0xFFFDE47B), Color(0xFFFF6B6B), Color(0xFF87CEEB),
              Color(0xFF4A8E9F), Color(0xFF90EE90), Color(0xFFFFFFFF),
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
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6 * s, offset: Offset(0, 2 * s))],
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
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20 * s, offset: Offset(0, 8 * s))],
                        ),
                        child: Column(
                          children: [
                            // Icon
                            Container(
                              padding: EdgeInsets.all(14 * s),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E607A).withAlpha(25),
                                border: Border.all(color: const Color(0xFF1E607A).withAlpha(50), width: 1.2),
                              ),
                              child: Icon(Icons.lock_reset_rounded, color: const Color(0xFF1E607A), size: 32 * s),
                            ),
                            SizedBox(height: 16 * s),

                            Text('Forgot Password', style: TextStyle(fontSize: 22 * s, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            SizedBox(height: 8 * s),
                            Text(
                              'Enter your registered email and phone number. We will send an OTP to verify your identity.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13 * s, color: const Color(0xFF64748B), height: 1.4),
                            ),

                            SizedBox(height: 24 * s),

                            // Email Input
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: TextStyle(fontSize: 14 * s, color: const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'parent@example.com',
                                errorText: _emailError,
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
                                filled: true, fillColor: const Color(0xFFF8FAFC),
                                errorStyle: TextStyle(fontSize: 11 * s),
                                contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 15 * s),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFF1E607A), width: 1.6)),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                              ),
                              onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
                            ),

                            SizedBox(height: 14 * s),

                            // Phone Input
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(fontSize: 14 * s, color: const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: '+919876543210',
                                errorText: _phoneError,
                                isDense: true,
                                labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 13 * s),
                                floatingLabelStyle: TextStyle(color: const Color(0xFF1E607A), fontWeight: FontWeight.w600),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(10 * s),
                                  child: Container(
                                    padding: EdgeInsets.all(6 * s),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withAlpha(20),
                                      borderRadius: BorderRadius.circular(8 * s),
                                    ),
                                    child: const Icon(Icons.phone_outlined, color: Color(0xFF10B981), size: 18),
                                  ),
                                ),
                                filled: true, fillColor: const Color(0xFFF8FAFC),
                                errorStyle: TextStyle(fontSize: 11 * s),
                                contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 15 * s),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFF1E607A), width: 1.6)),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                              ),
                              onChanged: (_) { if (_phoneError != null) setState(() => _phoneError = null); },
                            ),

                            SizedBox(height: 24 * s),

                            // Send OTP Button
                            Container(
                              width: double.infinity,
                              height: 46 * s,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF1E607A), Color(0xFF2B6B80)]),
                                borderRadius: BorderRadius.circular(24 * s),
                                boxShadow: [BoxShadow(color: const Color(0xFF1E607A).withAlpha(80), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24 * s),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24 * s),
                                  onTap: _isLoading ? null : _handleSendOtp,
                                  child: Center(
                                    child: _isLoading
                                        ? SizedBox(height: 20 * s, width: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                        : Text('Send OTP', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.4)),
                                  ),
                                ),
                              ),
                            ),
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
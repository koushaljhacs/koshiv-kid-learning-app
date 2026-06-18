/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/forgot_password_reset_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Forgot Password Reset Screen — New password form with user info display
 * 
 * Aim: Secure Password Reset Screen — Step 3 of Forgot Password Flow
 * Why: Displays verified user information and accepts new password.
 *      Calls POST /auth/forgot-password/reset with temp_token.
 *      On success navigates back to login screen.
 *      Validates password strength and confirm password match.
 * ============================================================
 */

import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  final String email;
  final String tempToken;
  final Map<String, dynamic> userData;

  const ForgotPasswordResetScreen({
    super.key,
    required this.email,
    required this.tempToken,
    required this.userData,
  });

  @override
  State<ForgotPasswordResetScreen> createState() => _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorText;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _fullName => widget.userData['full_name'] as String? ?? 'Parent';

  bool _validatePasswords() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() => _errorText = 'New password is required.');
      return false;
    }
    if (newPassword.length < 8) {
      setState(() => _errorText = 'Password must be at least 8 characters.');
      return false;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _errorText = 'Please confirm your new password.');
      return false;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorText = 'Passwords do not match.');
      return false;
    }

    setState(() => _errorText = null);
    return true;
  }

  Future<void> _handleResetPassword() async {
    if (!_validatePasswords()) return;

    final newPassword = _newPasswordController.text;

    setState(() => _isLoading = true);

    try {
      await _authRepository.forgotPasswordReset(
        widget.email,
        widget.tempToken,
        newPassword,
      );
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

                            Text('Reset Password', style: TextStyle(fontSize: 22 * s, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            SizedBox(height: 8 * s),
                            Text(
                              'Set a new password for your account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13 * s, color: const Color(0xFF64748B)),
                            ),

                            SizedBox(height: 16 * s),

                            // User Info Card
                            Container(
                              padding: EdgeInsets.all(14 * s),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12 * s),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8 * s),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1E607A).withAlpha(20),
                                    ),
                                    child: Icon(Icons.person, color: const Color(0xFF1E607A), size: 20 * s),
                                  ),
                                  SizedBox(width: 12 * s),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_fullName, style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                        SizedBox(height: 2 * s),
                                        Text(widget.email, style: TextStyle(fontSize: 12 * s, color: const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ],
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
                                        'Password reset successful. Please login with your new password.',
                                        style: TextStyle(fontSize: 13 * s, color: const Color(0xFF166534)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20 * s),
                              SizedBox(
                                width: double.infinity,
                                height: 46 * s,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E607A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 * s)),
                                  ),
                                  child: Text('Go to Login', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ),
                            ] else ...[
                              // New Password Input
                              _buildPasswordField(
                                controller: _newPasswordController,
                                label: 'New Password',
                                obscureText: _obscureNewPassword,
                                onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                s: s,
                              ),
                              SizedBox(height: 14 * s),

                              // Confirm Password Input
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                obscureText: _obscureConfirmPassword,
                                onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                s: s,
                              ),

                              if (_errorText != null) ...[
                                SizedBox(height: 14 * s),
                                Container(
                                  padding: EdgeInsets.all(12 * s),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10 * s),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                      SizedBox(width: 8 * s),
                                      Expanded(child: Text(_errorText!, style: TextStyle(fontSize: 12 * s, color: const Color(0xFFDC2626)))),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: 24 * s),

                              // Change Password Button
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
                                    onTap: _isLoading ? null : _handleResetPassword,
                                    child: Center(
                                      child: _isLoading
                                          ? SizedBox(height: 20 * s, width: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                          : Text('Change Password', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.4)),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required double s,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(fontSize: 14 * s, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 13 * s),
        floatingLabelStyle: TextStyle(color: const Color(0xFF1E607A), fontWeight: FontWeight.w600),
        prefixIcon: Padding(
          padding: EdgeInsets.all(10 * s),
          child: Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(20),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFF59E0B), size: 18),
          ),
        ),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B), size: 18 * s),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 15 * s),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFF1E607A), width: 1.6)),
      ),
    );
  }
}
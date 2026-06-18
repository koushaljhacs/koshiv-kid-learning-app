/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/parent_registration_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 2.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Parent Registration UI — Form fields for user data collection
 * Version 1.1.0 | Updated form fields per backend API spec
 * Version 1.1.1 | Added navigation to OtpVerificationScreen
 * Version 1.2.0 | Integrated AuthRepository.registerInit API call
 * Version 1.3.0 | Added real-time email format validation on focus loss
 * Version 1.4.0 | Added inline email error display
 * Version 1.5.0 | Added real-time email availability check with debounce
 * Version 2.0.0 | Complete UI Redesign — Premium Violet-Cyan gradient background, glassmorphic white cards, rounded inputs with Koshiv branding consistency matching role selection screen
 * 
 * Aim: Premium Parent Registration UI — Koshiv Design System
 * Why: Consistent visual language with role selection screen.
 *      Gradient background, white elevated cards, glassmorphic inputs.
 *      No heavy animations — clean, fast, professional.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'dart:async';
import '../data/auth_repository.dart';
import 'otp_verification_screen.dart';

class ParentRegistrationScreen extends StatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _childDobController = TextEditingController();
  final TextEditingController _childGradeController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();
  final FocusNode _emailFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  bool _isEmailAvailable = false;
  bool _isCheckingEmail = false;
  bool _showEmailStatus = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  void _onEmailChanged() {
    _debounceTimer?.cancel();
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isCheckingEmail = false;
        _showEmailStatus = false;
        _isEmailAvailable = false;
      });
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        _isCheckingEmail = false;
        _showEmailStatus = false;
        _isEmailAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _showEmailStatus = false;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkEmailAvailability(email);
    });
  }

  Future<void> _checkEmailAvailability(String email) async {
    try {
      final payload = {
        'parent_name': '_check_',
        'email': email,
        'password': '_check_',
        'child_name': '_check_',
      };
      await _authRepository.registerInit(payload);
      if (!mounted) return;
      setState(() {
        _emailError = null;
        _isCheckingEmail = false;
        _isEmailAvailable = true;
        _showEmailStatus = true;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.toLowerCase().contains('already registered') ||
          errorMsg.toLowerCase().contains('already in progress')) {
        setState(() {
          _emailError = 'Email already registered';
          _isCheckingEmail = false;
          _isEmailAvailable = false;
          _showEmailStatus = false;
        });
      } else {
        setState(() {
          _emailError = null;
          _isCheckingEmail = false;
          _isEmailAvailable = true;
          _showEmailStatus = true;
        });
      }
    }
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        setState(() {
          _emailError = null;
          _showEmailStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _parentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _childNameController.dispose();
    _childDobController.dispose();
    _childGradeController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final parentName = _parentNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final childName = _childNameController.text.trim();
    final childDob = _childDobController.text.trim();
    final childGrade = _childGradeController.text.trim();

    if (parentName.isEmpty || email.isEmpty || password.isEmpty || childName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields: Parent Name, Email, Password, and Child Name.')),
      );
      return;
    }

    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emailError!)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'parent_name': parentName,
        'email': email,
        'password': password,
        'child_name': childName,
      };
      if (phone.isNotEmpty) payload['phone_number'] = phone;
      if (childDob.isNotEmpty) payload['child_dob'] = childDob;
      if (childGrade.isNotEmpty) payload['child_grade'] = childGrade;

      await _authRepository.registerInit(payload);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.toLowerCase().contains('already registered') ||
          errorMsg.toLowerCase().contains('already in progress')) {
        setState(() => _emailError = 'Email already registered');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375;

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12 * scale),

                  // Back Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28 * scale),
                      ),
                    ),
                  ),

                  SizedBox(height: 16 * scale),

                  // Header
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 30 * scale.clamp(0.8, 1.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2))],
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Join Koshiv to monitor your child\'s learning progress.',
                    style: TextStyle(
                      fontSize: 14 * scale.clamp(0.85, 1.0),
                      color: Colors.white.withAlpha(230),
                    ),
                  ),

                  SizedBox(height: 24 * scale),

                  // Parent Details Card
                  _buildSectionCard(
                    context: context,
                    title: 'Parent Details',
                    scale: scale,
                    children: [
                      _buildInput(
                        controller: _parentNameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        scale: scale,
                      ),
                      SizedBox(height: 14 * scale),
                      _buildInput(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        suffixIcon: _isCheckingEmail
                            ? Padding(
                                padding: EdgeInsets.all(14 * scale),
                                child: SizedBox(
                                  height: 18 * scale,
                                  width: 18 * scale,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _showEmailStatus && _isEmailAvailable
                                ? Padding(
                                    padding: EdgeInsets.all(14 * scale),
                                    child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20 * scale),
                                  )
                                : null,
                        helperText: _showEmailStatus && _isEmailAvailable ? 'Email is available' : null,
                        scale: scale,
                      ),
                      SizedBox(height: 14 * scale),
                      _buildInput(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF64748B),
                            size: 22 * scale,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        scale: scale,
                      ),
                      SizedBox(height: 14 * scale),
                      _buildInput(
                        controller: _phoneController,
                        label: 'Phone Number (optional)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        scale: scale,
                      ),
                    ],
                  ),

                  SizedBox(height: 20 * scale),

                  // Child Details Card
                  _buildSectionCard(
                    context: context,
                    title: 'Child Details',
                    scale: scale,
                    children: [
                      _buildInput(
                        controller: _childNameController,
                        label: 'Child Full Name',
                        icon: Icons.child_care,
                        scale: scale,
                      ),
                      SizedBox(height: 14 * scale),
                      _buildInput(
                        controller: _childDobController,
                        label: 'Date of Birth (optional)',
                        icon: Icons.calendar_today,
                        hintText: 'YYYY-MM-DD',
                        scale: scale,
                      ),
                      SizedBox(height: 14 * scale),
                      _buildInput(
                        controller: _childGradeController,
                        label: 'Grade/Class (optional)',
                        icon: Icons.school,
                        scale: scale,
                      ),
                    ],
                  ),

                  SizedBox(height: 28 * scale),

                  // Send OTP Button
                  Container(
                    width: double.infinity,
                    height: 55 * scale,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E607A), Color(0xFF2B6B80)],
                      ),
                      borderRadius: BorderRadius.circular(30 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E607A).withAlpha(100),
                          blurRadius: 15 * scale,
                          offset: Offset(0, 6 * scale),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30 * scale),
                        onTap: _isLoading ? null : _handleSendOtp,
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  height: 24 * scale,
                                  width: 24 * scale,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 17 * scale.clamp(0.9, 1.0),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32 * scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required double scale,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale.clamp(0.9, 1.0),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 16 * scale),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double scale,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? errorText,
    String? hintText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: TextStyle(
        fontSize: 15 * scale.clamp(0.9, 1.0),
        color: const Color(0xFF1E293B),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 14 * scale.clamp(0.9, 1.0),
        ),
        floatingLabelStyle: TextStyle(
          color: const Color(0xFF1E607A),
          fontWeight: FontWeight.w600,
          fontSize: 13 * scale.clamp(0.9, 1.0),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 22 * scale),
        suffixIcon: suffixIcon,
        errorText: errorText,
        errorStyle: TextStyle(fontSize: 12 * scale),
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.green.shade600, fontSize: 12 * scale),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: const BorderSide(color: Color(0xFF1E607A), width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 18 * scale),
      ),
    );
  }
}
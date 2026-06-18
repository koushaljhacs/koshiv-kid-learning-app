/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/parent_registration_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.5.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Parent Registration UI — Form fields for user data collection
 * Version 1.1.0 | Updated form fields per backend API spec — Added child_name (required), child_dob, child_grade (optional), restructured layout into Parent Details and Child Details sections
 * Version 1.1.1 | Added navigation to OtpVerificationScreen on successful validation
 * Version 1.2.0 | Integrated AuthRepository.registerInit API call with loading state and error handling
 * Version 1.3.0 | Added real-time email format validation on focus loss
 * Version 1.4.0 | Added inline email error display — red border + dynamic text for format errors and "Email already registered" API errors, no SnackBar for email
 * Version 1.5.0 | Added real-time email availability check with 500ms debounce — shows green checkmark for valid+available, red error for invalid/registered while user types
 * 
 * Aim: Secure Parent Registration UI (Step 1) — Aligned with POST /api/v1/auth/register/init
 * Why: Real-time email validation while typing with 500ms debounce.
 *      Green "Available" for free emails, red "Already registered" for taken emails.
 *      Preserves Send OTP button validation as fallback.
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

    setState(() {
      _isLoading = true;
    });

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
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: email),
        ),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Parent'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Koshiv to monitor your child\'s learning progress.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              const Text(
                'Parent Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                  suffixIcon: _isCheckingEmail
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _showEmailStatus && _isEmailAvailable
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                            )
                          : null,
                  helperText: _showEmailStatus && _isEmailAvailable ? 'Email is available' : null,
                  helperStyle: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Child Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childNameController,
                decoration: const InputDecoration(
                  labelText: 'Child Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.child_care),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childDobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (optional)',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _childGradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade/Class (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send OTP', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/otp_verification_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 1.2.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial OTP Verification Screen — 6-digit box UI with resend timer
 * Version 1.1.0 | Integrated AuthRepository.registerComplete API call with loading state and error handling
 * Version 1.1.1 | Pass parentEmail to RegistrationSuccessScreen for email notification message
 * Version 1.2.0 | Added OtpMode support — Handles both registration and forgot password flows, conditional API calls and navigation
 * 
 * Aim: OTP Verification UI — Dual Mode (Registration + Forgot Password)
 * Why: Reusable OTP screen with mode-based logic.
 *      Registration mode calls registerComplete and navigates to success screen.
 *      Forgot password mode calls forgotPasswordVerifyOtp and navigates to reset screen.
 *      Clean separation without duplicating the OTP UI.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'dart:async';
import '../data/auth_repository.dart';
import 'registration_success_screen.dart';
import 'forgot_password_reset_screen.dart';

enum OtpMode { registration, forgotPassword }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpMode mode;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.mode = OtpMode.registration,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final AuthRepository _authRepository = AuthRepository();

  int _resendTimer = 45;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;

  bool get _isForgotPassword => widget.mode == OtpMode.forgotPassword;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _resendTimer = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 1) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerify() async {
    final otp = _getOtp();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isForgotPassword) {
        // Forgot Password Flow: Verify OTP, get temp_token
        final response = await _authRepository.forgotPasswordVerifyOtp(widget.email, otp);

        if (!mounted) return;

        final tempToken = response['temp_token'] as String;
        final user = response['user'] as Map<String, dynamic>;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => ForgotPasswordResetScreen(
              email: widget.email,
              tempToken: tempToken,
              userData: user,
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
      } else {
        // Registration Flow: Complete registration
        final response = await _authRepository.registerComplete(widget.email, otp);

        if (!mounted) return;

        final childHandle = response['child_handle'] as String;
        final childPin = response['child_pin'] as String;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationSuccessScreen(
              childHandle: childHandle,
              childPin: childPin,
              parentEmail: widget.email,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleResend() {
    if (!_canResend) return;

    debugPrint('Resending OTP to: ${widget.email}');
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent to your email.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 375).clamp(0.85, 1.05);

    final title = _isForgotPassword ? 'Verify OTP' : 'Verify Email';
    final subtitle = _isForgotPassword
        ? 'Enter the 6-digit code sent to\n${widget.email}'
        : 'Enter the 6-digit code sent to\n${widget.email}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32 * s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 64 * s,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 24 * s),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28 * s,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12 * s),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16 * s,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40 * s),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48 * s,
                    height: 56 * s,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 24 * s,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  );
                }),
              ),
              SizedBox(height: 32 * s),

              // Resend Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Resend OTP in ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '0:${_resendTimer.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * s),

              // Resend Button
              TextButton(
                onPressed: _canResend ? _handleResend : null,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: _canResend ? Colors.deepPurple : Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 32 * s),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50 * s,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  child: _isLoading
                      ? SizedBox(
                          height: 24 * s,
                          width: 24 * s,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Verify', style: TextStyle(fontSize: 16 * s)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
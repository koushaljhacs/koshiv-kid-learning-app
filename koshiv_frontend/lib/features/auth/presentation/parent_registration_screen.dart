/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/parent_registration_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 2.0.1
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Parent Registration UI — Form fields for user data collection
 * Version 1.1.0 | Updated form fields per backend API spec
 * Version 1.1.1 | Added navigation to OtpVerificationScreen
 * Version 1.2.0 | Integrated AuthRepository.registerInit API call
 * Version 1.3.0 | Added real-time email format validation on focus loss
 * Version 1.4.0 | Added inline email error display
 * Version 1.5.0 | Added real-time email availability check with debounce
 * Version 2.0.0 | Complete UI Redesign — Premium gradient, unified white card, proper styled back button, bottom buttons, removed autofocus, premium colored icons
 * Version 2.0.1 | Added email_dispatched flag check in _handleSendOtp — Only navigates to OTP screen when email actually dispatched, shows inline error on failure
 * 
 * Aim: Premium Parent Registration UI — Koshiv Design System
 * Why: Proper outlined back button with arrow icon + label for professional look.
 *      Premium styled icons in soft colored containers.
 *      email_dispatched flag ensures OTP screen only opens when email sent.
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
      setState(() { _emailError = null; _isCheckingEmail = false; _showEmailStatus = false; _isEmailAvailable = false; });
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() { _emailError = 'Please enter a valid email address'; _isCheckingEmail = false; _showEmailStatus = false; _isEmailAvailable = false; });
      return;
    }
    setState(() { _isCheckingEmail = true; _showEmailStatus = false; });
    _debounceTimer = Timer(const Duration(milliseconds: 500), () => _checkEmailAvailability(email));
  }

  Future<void> _checkEmailAvailability(String email) async {
    try {
      final dispatched = await _authRepository.registerInit({'parent_name': '_check_', 'email': email, 'password': '_check_', 'child_name': '_check_'});
      if (!mounted) return;
      setState(() { _emailError = null; _isCheckingEmail = false; _isEmailAvailable = dispatched; _showEmailStatus = dispatched; });
    } catch (e) {
      if (!mounted) return;
      final m = e.toString().replaceAll('Exception: ', '');
      if (m.toLowerCase().contains('already registered') || m.toLowerCase().contains('already in progress')) {
        setState(() { _emailError = 'Email already registered'; _isCheckingEmail = false; _isEmailAvailable = false; _showEmailStatus = false; });
      } else {
        setState(() { _emailError = null; _isCheckingEmail = false; _isEmailAvailable = true; _showEmailStatus = true; });
      }
    }
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus && _emailController.text.trim().isEmpty) {
      setState(() { _emailError = null; _showEmailStatus = false; });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _parentNameController.dispose(); _emailController.dispose(); _passwordController.dispose();
    _phoneController.dispose(); _childNameController.dispose(); _childDobController.dispose(); _childGradeController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_emailError!)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{'parent_name': parentName, 'email': email, 'password': password, 'child_name': childName};
      if (phone.isNotEmpty) payload['phone_number'] = phone;
      if (childDob.isNotEmpty) payload['child_dob'] = childDob;
      if (childGrade.isNotEmpty) payload['child_grade'] = childGrade;

      final emailDispatched = await _authRepository.registerInit(payload);
      if (!mounted) return;

      if (emailDispatched) {
        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => OtpVerificationScreen(email: email),
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
        ));
      } else {
        setState(() => _emailError = 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      final m = e.toString().replaceAll('Exception: ', '');
      if (m.toLowerCase().contains('already registered') || m.toLowerCase().contains('already in progress')) {
        setState(() => _emailError = 'Email already registered');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 375).clamp(0.82, 1.05);

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDE47B), Color(0xFFFF6B6B), Color(0xFF87CEEB), Color(0xFF4A8E9F), Color(0xFF90EE90), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 8 * s),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22 * s),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20 * s, offset: Offset(0, 8 * s))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  _premiumIcon(icon: Icons.person_add_rounded, color: const Color(0xFF1E607A), s: s, size: 30 * s),
                                  SizedBox(height: 10 * s),
                                  Text('Create Account', style: TextStyle(fontSize: 22 * s, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  SizedBox(height: 4 * s),
                                  Text('Join Koshiv to monitor your child\'s learning.', textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12 * s, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),

                            SizedBox(height: sh * 0.025),
                            _sectionDivider(s: s),
                            SizedBox(height: sh * 0.018),

                            _sectionHeader(title: 'Parent Details', required: true, s: s),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _parentNameController, label: 'Full Name', icon: Icons.person_outline, iconColor: const Color(0xFF6366F1), required: true, s: s),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _emailController, focusNode: _emailFocusNode, label: 'Email', icon: Icons.email_outlined,
                              iconColor: const Color(0xFF0EA5E9), keyboardType: TextInputType.emailAddress, required: true, errorText: _emailError, s: s,
                              suffix: _isCheckingEmail
                                  ? Padding(padding: EdgeInsets.all(10 * s), child: SizedBox(height: 14 * s, width: 14 * s, child: const CircularProgressIndicator(strokeWidth: 2)))
                                  : _showEmailStatus && _isEmailAvailable
                                      ? Padding(padding: EdgeInsets.all(10 * s), child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 16 * s))
                                      : null,
                              helper: _showEmailStatus && _isEmailAvailable ? 'Available' : null,
                            ),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, iconColor: const Color(0xFFF59E0B), required: true,
                              obscureText: _obscurePassword, s: s,
                              suffix: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B), size: 18 * s),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                            ),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _phoneController, label: 'Phone', icon: Icons.phone_outlined, iconColor: const Color(0xFF10B981), keyboardType: TextInputType.phone, s: s),

                            SizedBox(height: sh * 0.022),
                            _sectionDivider(s: s),
                            SizedBox(height: sh * 0.018),

                            _sectionHeader(title: 'Child Details', required: true, s: s),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _childNameController, label: 'Child Full Name', icon: Icons.child_care, iconColor: const Color(0xFFEC4899), required: true, s: s),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _childDobController, label: 'Date of Birth', icon: Icons.calendar_today, iconColor: const Color(0xFF8B5CF6), hint: 'YYYY-MM-DD', s: s),
                            SizedBox(height: 10 * s),
                            _buildInput(controller: _childGradeController, label: 'Grade/Class', icon: Icons.school, iconColor: const Color(0xFF14B8A6), s: s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 14 * s),
                decoration: BoxDecoration(color: Colors.white.withAlpha(15)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity, height: 48 * s,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E607A), Color(0xFF2B6B80)]), borderRadius: BorderRadius.circular(26 * s),
                        boxShadow: [BoxShadow(color: const Color(0xFF1E607A).withAlpha(80), blurRadius: 12 * s, offset: Offset(0, 5 * s))]),
                      child: Material(
                        color: Colors.transparent, borderRadius: BorderRadius.circular(26 * s),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26 * s), onTap: _isLoading ? null : _handleSendOtp,
                          child: Center(
                            child: _isLoading
                                ? SizedBox(height: 20 * s, width: 20 * s, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text('Send OTP', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.6)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    Container(
                      width: double.infinity, height: 44 * s,
                      decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(26 * s), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Material(
                        color: Colors.transparent, borderRadius: BorderRadius.circular(26 * s),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26 * s), onTap: () => Navigator.pop(context),
                          child: Center(child: Text('Cancel', style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
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
    );
  }

  Widget _premiumIcon({required IconData icon, required Color color, required double s, double size = 28}) {
    return Container(
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _sectionDivider({required double s}) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _sectionHeader({required String title, bool required = false, required double s}) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        if (required) ...[
          SizedBox(width: 3 * s),
          Text('*', style: TextStyle(fontSize: 14 * s, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
        ],
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required double s,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool required = false,
    String? errorText,
    String? hint,
    String? helper,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller, focusNode: focusNode, keyboardType: keyboardType, obscureText: obscureText,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: TextStyle(fontSize: 13 * s, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint, isDense: true,
        labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 12 * s),
        floatingLabelStyle: TextStyle(color: const Color(0xFF1E607A), fontWeight: FontWeight.w600, fontSize: 11 * s),
        prefixIcon: Padding(
          padding: EdgeInsets.all(10 * s),
          child: Container(
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(icon, color: iconColor, size: 16 * s),
          ),
        ),
        suffixIcon: suffix, errorText: errorText, errorStyle: TextStyle(fontSize: 10 * s),
        helperText: helper, helperStyle: TextStyle(color: Colors.green.shade600, fontSize: 10 * s), helperMaxLines: 1,
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 14 * s),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFF1E607A), width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12 * s), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}
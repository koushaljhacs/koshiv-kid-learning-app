/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/role_selection_screen.dart
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Role Selection Screen — Parent/Student login and registration entry points
 * Version 1.1.0 | Wired Login as Parent button to navigate to ParentLoginScreen via AppRoutes
 * Version 1.1.1 | Wired Login as Student button to navigate to StudentLoginScreen via AppRoutes
 * Version 1.1.2 | Wired Register as Parent button to navigate to ParentRegistrationScreen via AppRoutes
 * Version 2.0.0 | Complete redesign — Glassmorphism theme with gradient, role cards, morph animation
 * Version 2.0.1 | Responsive layout — Dynamic measurements via MediaQuery, floating label inputs
 * Version 2.0.2 | Replaced student icon with custom avatar image from assets
 * Version 2.0.3 | Replaced parent icon with custom family avatar image from assets
 * 
 * Aim: Unified Role Selection + Authentication Screen
 * Why: To provide an engaging, responsive, child-friendly role selection experience.
 *      Uses custom cartoon avatars for both student and parent cards.
 *      Dynamic measurements ensure perfect fit across all device sizes.
 *      Maintains strict RBAC and COPPA data isolation.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/routes/app_routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    _animationController.forward(from: 0);
  }

  void _onBackToRoles() {
    _animationController.reverse().then((_) {
      setState(() {
        _selectedRole = null;
        _emailController.clear();
        _passwordController.clear();
        _handleController.clear();
        _pinController.clear();
      });
    });
  }

  void _handleLogin() {
    if (_selectedRole == 'parent') {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password.')),
        );
        return;
      }

      debugPrint('Initiating Parent Login API Call for: $email');
    } else if (_selectedRole == 'student') {
      final handle = _handleController.text.trim();
      final pin = _pinController.text.trim();

      if (handle.isEmpty || pin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter handle and PIN.')),
        );
        return;
      }

      debugPrint('Initiating Student Login API Call for handle: $handle');
    }
  }

  double _screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  double _screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double _scaleFactor(BuildContext context) => math.min(_screenWidth(context) / 375, 1.15);
  double _responsiveFont(double size, BuildContext context) => size * _scaleFactor(context);
  double _circleSize(BuildContext context) => math.min((_screenWidth(context) - 68) / 2 * 0.45, 80);

  @override
  Widget build(BuildContext context) {
    final scale = _scaleFactor(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A8E9F), Color(0xFF1E4D5D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _selectedRole == null
              ? _buildRoleSelectionView(context, scale)
              : _buildLoginFormView(context, scale),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionView(BuildContext context, double scale) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
        child: Column(
          children: [
            SizedBox(height: _screenHeight(context) * 0.05),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, color: Colors.white, size: 32 * scale),
                SizedBox(width: 8 * scale),
                Text(
                  'Koshiv',
                  style: TextStyle(
                    fontSize: _responsiveFont(28, context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            Text(
              'Learning App for Kids',
              style: TextStyle(
                fontSize: _responsiveFont(14, context),
                color: Colors.white.withAlpha((0.70 * 255).round()),
              ),
            ),

            SizedBox(height: _screenHeight(context) * 0.06),

            Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: _responsiveFont(32, context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              'Who is learning today?',
              style: TextStyle(
                fontSize: _responsiveFont(16, context),
                color: Colors.white.withAlpha((0.70 * 255).round()),
              ),
            ),

            SizedBox(height: _screenHeight(context) * 0.05),

            Row(
              children: [
                Expanded(child: _buildRoleCard(context, 'student', scale)),
                SizedBox(width: 20 * scale),
                Expanded(child: _buildRoleCard(context, 'parent', scale)),
              ],
            ),

            SizedBox(height: _screenHeight(context) * 0.05),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    fontSize: _responsiveFont(15, context),
                    color: Colors.white.withAlpha((0.70 * 255).round()),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.parentRegister);
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: _responsiveFont(15, context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFDE47B),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32 * scale),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role, double scale) {
    final isStudent = role == 'student';
    final label = isStudent ? 'Student' : 'Parent';
    final color = isStudent ? const Color(0xFFFDE47B) : const Color(0xFF7EC8E3);
    final circleSize = _circleSize(context);
    final imagePath = isStudent
        ? 'assets/images/student_avatar.png'
        : 'assets/images/parent_avatar.png';
    final fallbackIcon = isStudent ? Icons.child_care : Icons.person;

    return GestureDetector(
      onTap: () => _onRoleSelected(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          vertical: 28 * scale,
          horizontal: 16 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.12 * 255).round()),
          borderRadius: BorderRadius.circular(24 * scale),
          border: Border.all(
            color: Colors.white.withAlpha((0.25 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.10 * 255).round()),
              blurRadius: 15 * scale,
              offset: Offset(0, 8 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha((0.20 * 255).round()),
                border: Border.all(color: color, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(fallbackIcon, size: circleSize * 0.50, color: color);
                  },
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
            Text(
              'Login as\n$label',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFont(16, context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            SizedBox(height: 8 * scale),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withAlpha((0.60 * 255).round()),
              size: 20 * scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginFormView(BuildContext context, double scale) {
    final isParent = _selectedRole == 'parent';
    final title = isParent ? 'Parent Login' : 'Student Login';
    final subtitle = isParent
        ? 'Enter your email and password.'
        : 'Enter your Koshiv Handle and Secret PIN.';
    final roleIcon = isParent ? Icons.person : Icons.child_care;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _slideAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            child: Column(
              children: [
                SizedBox(height: _screenHeight(context) * 0.04),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withAlpha((0.80 * 255).round()),
                      size: 28 * scale,
                    ),
                    onPressed: _onBackToRoles,
                  ),
                ),
                SizedBox(height: 8 * scale),

                Container(
                  padding: EdgeInsets.all(24 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(24 * scale),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.30 * 255).round()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.10 * 255).round()),
                        blurRadius: 20 * scale,
                        offset: Offset(0, 10 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56 * scale,
                        height: 56 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha((0.18 * 255).round()),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.30 * 255).round()),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(roleIcon, size: 28 * scale, color: Colors.white),
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: _responsiveFont(26, context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: _responsiveFont(14, context),
                          color: Colors.white.withAlpha((0.70 * 255).round()),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24 * scale),

                      if (isParent) ...[
                        _buildGlassField(
                          context: context,
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _buildGlassField(
                          context: context,
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withAlpha((0.80 * 255).round()),
                              size: 22 * scale,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          scale: scale,
                        ),
                      ] else ...[
                        _buildGlassField(
                          context: context,
                          controller: _handleController,
                          label: 'Student Handle',
                          icon: Icons.person_outline,
                          autocorrect: false,
                          scale: scale,
                        ),
                        SizedBox(height: 16 * scale),
                        _buildGlassField(
                          context: context,
                          controller: _pinController,
                          label: 'Secret PIN',
                          icon: Icons.dialpad,
                          keyboardType: TextInputType.number,
                          obscureText: _obscurePin,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withAlpha((0.80 * 255).round()),
                              size: 22 * scale,
                            ),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          scale: scale,
                        ),
                      ],
                      SizedBox(height: 24 * scale),

                      Container(
                        width: double.infinity,
                        height: 55 * scale,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A8E9F), Color(0xFF2B6B80)],
                          ),
                          borderRadius: BorderRadius.circular(30 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.20 * 255).round()),
                              blurRadius: 10 * scale,
                              offset: Offset(0, 4 * scale),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30 * scale),
                            ),
                          ),
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: _responsiveFont(18, context),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * scale),
                GestureDetector(
                  onTap: () => debugPrint('Navigating to Forgot Password...'),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: _responsiveFont(15, context),
                      color: Colors.white.withAlpha((0.70 * 255).round()),
                    ),
                  ),
                ),
                SizedBox(height: 32 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool autocorrect = true,
    Widget? suffixIcon,
    double scale = 1.0,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: autocorrect,
      style: TextStyle(
        color: Colors.white,
        fontSize: _responsiveFont(16, context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withAlpha((0.70 * 255).round()),
          fontSize: _responsiveFont(14, context),
        ),
        floatingLabelStyle: TextStyle(
          color: const Color(0xFFFDE47B),
          fontSize: _responsiveFont(12, context),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withAlpha((0.80 * 255).round()),
          size: 22 * scale,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withAlpha((0.10 * 255).round()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: BorderSide(
            color: Colors.white.withAlpha((0.25 * 255).round()),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: BorderSide(
            color: Colors.white.withAlpha((0.25 * 255).round()),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14 * scale),
          borderSide: const BorderSide(
            color: Color(0xFFFDE47B),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 16 * scale,
        ),
      ),
    );
  }
}
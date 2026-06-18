/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: Koshiv - Learning App for Kids
 * Role: Frontend Developer
 * Module: auth_presentation
 * File: lib/features/auth/presentation/role_selection_screen.dart
 * Original File Version: 1.0.0
 * Current File Version: 2.4.1
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Role Selection Screen
 * Version 1.1.0 | Wired Login as Parent button
 * Version 1.1.1 | Wired Login as Student button
 * Version 1.1.2 | Wired Register as Parent button
 * Version 2.0.0 | Complete redesign — Glassmorphism theme
 * Version 2.1.0 | Added typewriter effect and pulse animation
 * Version 2.2.0 | Layout fixed using IntrinsicHeight
 * Version 2.3.0 | Figma Pro UI/UX Redesign — Premium Violet-Cyan gradient
 * Version 2.4.0 | Solid White Cards — Smart blend workaround for JPG white backgrounds
 * Version 2.4.1 | Fixed Android system back button — now returns to role cards instead of exiting app
 * 
 * Aim: Unified Role Selection + Authentication Screen
 * Why: Delightful animated entry with typewriter text and subtle pulse guide.
 *      Premium Violet-Cyan gradient with solid white cards for clean avatar display.
 *      Android back button properly handled to navigate back to role selection.
 *      Dynamic responsive layout for all screen sizes.
 *      Maintains strict RBAC and COPPA data isolation.
 * ============================================================
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
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

  String _displayedTitle = '';
  bool _showSubtitle = false;
  int _charIndex = 0;
  final String _fullTitle = 'Welcome Back!';
  Timer? _typewriterTimer;

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
    _startTypewriter();
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) {
      if (_charIndex < _fullTitle.length) {
        setState(() {
          _displayedTitle += _fullTitle[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showSubtitle = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
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

  double _screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  double _screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  double _scaleFactor(BuildContext context) =>
      math.min(_screenWidth(context) / 375, 1.15);
  double _responsiveFont(double size, BuildContext context) =>
      size * _scaleFactor(context);

@override
Widget build(BuildContext context) {
  final scale = _scaleFactor(context);

  return PopScope(
    canPop: _selectedRole == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _selectedRole != null) {
        _onBackToRoles();
      }
    },
    child: Scaffold(
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
          child: _selectedRole == null
              ? _buildRoleSelectionView(context, scale)
              : _buildLoginFormView(context, scale),
        ),
      ),
    ),
  );
}

  Widget _buildRoleSelectionView(BuildContext context, double scale) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Column(
          children: [
            SizedBox(height: _screenHeight(context) * 0.04),

            _FloatingWidget(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Koshiv',
                        style: TextStyle(
                          fontSize: _responsiveFont(36, context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black26,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Icon(Icons.school, color: Colors.white, size: 36 * scale),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'Learning App for Kids',
                    style: TextStyle(
                      fontSize: _responsiveFont(16, context),
                      color: Colors.white.withAlpha((0.90 * 255).round()),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _screenHeight(context) * 0.05),

            Text(
              _displayedTitle,
              style: TextStyle(
                fontSize: _responsiveFont(34, context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),

            AnimatedOpacity(
              opacity: _showSubtitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              child: Text(
                'Who is learning today?',
                style: TextStyle(
                  fontSize: _responsiveFont(18, context),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 8 * scale),

            _showSubtitle
                ? _PulseText(
                    text: 'Please select your role',
                    fontSize: _responsiveFont(16, context),
                    color: Colors.white.withAlpha((0.85 * 255).round()),
                  )
                : const SizedBox(height: 20),

            SizedBox(height: _screenHeight(context) * 0.04),

            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  Expanded(
                    child: _buildExactRoleCard(
                      context: context,
                      role: 'student',
                      title: 'STUDENT\n(छात्र)',
                      desc: 'Learn with fun, access assignments, and more.',
                      btnText: "I'M A STUDENT",
                      btnColor: const Color(0xFF1E607A), // Deep Blue Button
                      imagePath: 'assets/images/student_avatar.png',
                      scale: scale,
                    ),
                  ),
                  SizedBox(width: 16 * scale),
                  Expanded(
                    child: _buildExactRoleCard(
                      context: context,
                      role: 'parent',
                      title: 'PARENT\n(माता-पिता)',
                      desc: 'Track progress, receive updates, and guide.',
                      btnText: "I'M A PARENT",
                      btnColor: const Color(0xFFECA02B), // Warm Orange Button
                      imagePath: 'assets/images/parent_avatar.png',
                      scale: scale,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _screenHeight(context) * 0.05),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    fontSize: _responsiveFont(15, context),
                    color: Colors.white, 
                    fontWeight: FontWeight.w500,
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
                      color: const Color(0xFFECA02B), // Matches parent button
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
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

  Widget _buildExactRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String desc,
    required String btnText,
    required Color btnColor,
    required String imagePath,
    required double scale,
  }) {
    return GestureDetector(
      onTap: () => _onRoleSelected(role),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          // SOLID WHITE BACKGROUND: Hides the image's white background completely
          color: Colors.white,
          borderRadius: BorderRadius.circular(24 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).round()), 
              blurRadius: 25 * scale,
              offset: Offset(0, 10 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 110 * scale,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    role == 'student' ? Icons.child_care : Icons.family_restroom,
                    size: 60 * scale,
                    color: Colors.grey.shade400,
                  );
                },
              ),
            ),
            SizedBox(height: 16 * scale),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFont(15, context),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B), 
                height: 1.2,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFont(11.5, context),
                color: const Color(0xFF475569), 
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const Spacer(), 
            SizedBox(height: 16 * scale),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12 * scale),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(30 * scale),
                boxShadow: [
                  BoxShadow(
                    color: btnColor.withAlpha((0.40 * 255).round()),
                    blurRadius: 10 * scale,
                    offset: Offset(0, 4 * scale),
                  )
                ]
              ),
              child: Center(
                child: Text(
                  btnText,
                  style: TextStyle(
                    fontSize: _responsiveFont(12, context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
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
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * scale),
            child: Column(
              children: [
                SizedBox(height: _screenHeight(context) * 0.04),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: _onBackToRoles,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28 * scale,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8 * scale),

                ClipRRect(
                  borderRadius: BorderRadius.circular(28 * scale),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: EdgeInsets.all(24 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.20 * 255).round()),
                        borderRadius: BorderRadius.circular(28 * scale),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.60 * 255).round()),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.10 * 255).round()),
                            blurRadius: 30 * scale,
                            offset: Offset(0, 15 * scale),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 70 * scale,
                            height: 70 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha((0.50 * 255).round()),
                                  Colors.white.withAlpha((0.10 * 255).round()),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withAlpha((0.80 * 255).round()),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              roleIcon,
                              size: 34 * scale,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16 * scale),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: _responsiveFont(26, context),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: _responsiveFont(14, context),
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32 * scale),

                          if (isParent) ...[
                            _buildGlassField(
                              context: context,
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              scale: scale,
                            ),
                            SizedBox(height: 20 * scale),
                            _buildGlassField(
                              context: context,
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF334155),
                                  size: 22 * scale,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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
                            SizedBox(height: 20 * scale),
                            _buildGlassField(
                              context: context,
                              controller: _pinController,
                              label: 'Secret PIN',
                              icon: Icons.dialpad,
                              keyboardType: TextInputType.number,
                              obscureText: _obscurePin,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF334155),
                                  size: 22 * scale,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                              scale: scale,
                            ),
                          ],
                          SizedBox(height: 32 * scale),

                          Container(
                            width: double.infinity,
                            height: 55 * scale,
                            decoration: BoxDecoration(
                              color: isParent ? const Color(0xFFECA02B) : const Color(0xFF1E607A),
                              borderRadius: BorderRadius.circular(30 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: (isParent ? const Color(0xFFECA02B) : const Color(0xFF1E607A)).withAlpha((0.40 * 255).round()),
                                  blurRadius: 15 * scale,
                                  offset: Offset(0, 6 * scale),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30 * scale),
                                onTap: _handleLogin,
                                child: Center(
                                  child: Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: _responsiveFont(18, context),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24 * scale),
                GestureDetector(
                  onTap: () => debugPrint('Navigating to Forgot Password...'),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: _responsiveFont(15, context),
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      fontWeight: FontWeight.w500,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: autocorrect,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: _responsiveFont(16, context),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: const Color(0xFF475569),
              fontSize: _responsiveFont(14, context),
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: const Color(0xFF1E607A),
              fontSize: _responsiveFont(14, context),
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF475569),
              size: 24 * scale,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withAlpha((0.60 * 255).round()), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: BorderSide(
                color: Colors.white.withAlpha((0.80 * 255).round()),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: BorderSide(
                color: Colors.white.withAlpha((0.80 * 255).round()),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: const BorderSide(color: Color(0xFF1E607A), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 20 * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingWidget extends StatefulWidget {
  final Widget child;

  const _FloatingWidget({required this.child});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _PulseText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;

  const _PulseText({
    required this.text,
    required this.fontSize,
    required this.color,
  });

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.fontSize, 
          color: widget.color,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
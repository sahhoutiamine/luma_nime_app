import 'dart:ui';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:luma_nome_app/Sign-in-up/login_page.dart';
import 'package:luma_nome_app/pages/home_page.dart';
import 'package:luma_nome_app/services/auth_service.dart';

const Color _backgroundColor = Color(0xFF0A0A0F);
const Color _primaryColor = Color(0xFF7C4CFE);
const Color _secondaryColor = Color(0xFF9D5DFF);
const Color _accentColor = Color(0xFF00E5FF);
const Color _successColor = Color(0xFF00FF94);
const Color _textColor = Colors.white;
const Color _cardColor = Color(0xFF151520);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.bounceOut),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_particleController);
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true;
    });

    final authService = AuthService();

    if (passwordController.text == confirmPasswordController.text) {
      try {
        await authService.signUpwithEmailPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await user.updateProfile(
            displayName: usernameController.text.trim(),
          );

          final uid = user.uid;

          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Success animation
          await _successController.forward();
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const HomePage(),
                transitionDuration: const Duration(milliseconds: 1000),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
              ),
            );
          }
        } else {
          throw Exception('User registration failed');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(e.toString());
      }
    } else {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("Passwords don't match");
    }
  }

  bool _validateInputs() {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showErrorDialog("Please fill in all fields");
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorDialog("Password must be at least 6 characters long");
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorDialog("Please enter a valid email address");
      return false;
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cardColor.withOpacity(0.9),
                  _cardColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Registration Error",
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade500, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Got it",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildHeader(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildRegisterForm(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (isLoading) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.8,
          colors: [
            _accentColor.withOpacity(0.12),
            _backgroundColor,
            _backgroundColor,
            _primaryColor.withOpacity(0.08),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(_rotationAnimation.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * _successAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _successAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_successColor, _successColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _successColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_primaryColor, _secondaryColor, _accentColor],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Join Us',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor.withOpacity(0.2), _primaryColor.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Text(
            'Create your cosmic account',
            style: TextStyle(
              fontSize: 16,
              color: _textColor.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Column(
            children: [
              _buildInputField(
                controller: usernameController,
                label: 'Username',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 40),
              _buildRegisterButton(),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardColor.withOpacity(0.9),
            _cardColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _primaryColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.8), _accentColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          suffixIcon: isPassword
              ? Container(
                  margin: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _primaryColor,
                    ),
                    onPressed: onToggleVisibility,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _primaryColor,
                _secondaryColor,
                _accentColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.6),
                blurRadius: 25 + (math.sin(_pulseController.value * 2 * math.pi) * 8),
                spreadRadius: 3 + (math.sin(_pulseController.value * 2 * math.pi) * 2),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isLoading ? null : register,
              child: Center(
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Creating Account...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _accentColor.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'or',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
);
          },
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_accentColor, _primaryColor],
            ).createShader(bounds),
            child: const Text(
              "Sign In",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = _primaryColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = _accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = _successColor.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.04) + 
                (math.sin(animationValue + i * 0.5) * 40);
      final y = (size.height * 0.15) + (i * size.height * 0.03) + 
                (math.cos(animationValue + i * 0.3) * 25);
      
      final radius = 1.5 + math.sin(animationValue + i * 0.7) * 1.2;
      
      Paint currentPaint;
      if (i % 3 == 0) {
        currentPaint = paint1;
      } else if (i % 3 == 1) {
        currentPaint = paint2;
      } else {
        currentPaint = paint3;
      }
      
      canvas.drawCircle(Offset(x, y), radius, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
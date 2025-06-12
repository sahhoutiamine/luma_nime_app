import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:luma_nome_app/Sign-in-up/register_page.dart';
import 'package:luma_nome_app/pages/home_page.dart';
import 'package:luma_nome_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _backgroundColor = Color(0xFF0A0A0F);
const Color _primaryColor = Color(0xFF7C4CFE);
const Color _secondaryColor = Color(0xFF9D5DFF);
const Color _accentColor = Color(0xFF00E5FF);
const Color _textColor = Colors.white;
const Color _cardColor = Color(0xFF151520);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_particleController);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showErrorDialog("Please fill in all fields");
      return;
    }

    setState(() {
      isLoading = true;
    });

    final authService = AuthService();

    try {
      await authService.signInwithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserLoggedIn', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const HomePage(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(e.toString());
      }
    }
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
                  "Authentication Error",
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       MediaQuery.of(context).padding.bottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const SizedBox(height: 60),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLoginForm(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            _primaryColor.withOpacity(0.15),
            _backgroundColor,
            _backgroundColor,
            _accentColor.withOpacity(0.1),
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

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_primaryColor, _secondaryColor, _accentColor],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Welcome Back',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor.withOpacity(0.2), _accentColor.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            'Sign in to your universe',
            style: TextStyle(
              fontSize: 16,
              color: _textColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildInputField(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              _buildInputField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 40),
              _buildLoginButton(),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardColor.withOpacity(0.8),
            _cardColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.8), _secondaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: isPassword
              ? Container(
                  margin: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _primaryColor,
                _secondaryColor,
                _primaryColor,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.5),
                blurRadius: 20 + (math.sin(_pulseController.value * 2 * math.pi) * 5),
                spreadRadius: 2 + (math.sin(_pulseController.value * 2 * math.pi) * 1),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isLoading ? null : login,
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
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
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _primaryColor.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: _textColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      
      mainAxisAlignment: MainAxisAlignment.center,
      
      children: [
        
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        InkWell(
  onTap: () {
    Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => RegisterPage()),
);
  },
  hoverColor: Colors.transparent, // لإزالة تأثير الخلفية عند المرور
  child: ShaderMask(

    shaderCallback: (bounds) => LinearGradient(
      colors: [_primaryColor, _accentColor],
    ).createShader(bounds),
    child: const Text(
      "Create Account",
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
    final paint = Paint()
      ..color = _primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = _accentColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.05) + 
                (math.sin(animationValue + i) * 30);
      final y = (size.height * 0.1) + (i * size.height * 0.04) + 
                (math.cos(animationValue + i) * 20);
      
      canvas.drawCircle(
        Offset(x, y),
        2 + math.sin(animationValue + i) * 1,
        i % 2 == 0 ? paint : paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:luma_nome_app/Sign-in-up/login_page.dart';
import 'package:luma_nome_app/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // الانتظار لمدة 3 ثواني
    await Future.delayed(Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      bool? isLoggedIn = prefs.getBool('isUserLoggedIn');

      // إذا كان المستخدم مسجل دخوله
      if (isLoggedIn != null && isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      print('حدث خطأ في الانتقال: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('خطأ'),
          content: Text('تعذر فتح التطبيق، يرجى المحاولة لاحقاً'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo_tr.png',
      width: 150,
      height: 150,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.movie,
        size: 150,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121215),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

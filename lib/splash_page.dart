import 'package:flutter/material.dart';
import 'package:luma_nome_app/pages/home_page.dart';

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
    await Future.delayed(Duration(seconds: 3));

    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
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
    try {
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
    } catch (e) {
      return Icon(
        Icons.movie,
        size: 150,
        color: Colors.white,
      );
    }
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
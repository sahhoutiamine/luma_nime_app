import 'package:flutter/material.dart';
import 'package:luma_nome_app/Sign-in-up/login_page.dart';
import 'package:luma_nome_app/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isUserLoggedIn');
    setState(() {
      isUserLoggedIn = loggedIn ?? false;
    });
  }

  @override
  Widget build(BuildContext context) { 
    if (isUserLoggedIn) {
      return const HomePage(); 
    } else {
      return const LoginPage();  
    }
  }
}

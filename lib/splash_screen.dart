import 'dart:async';

import 'package:apg_scanner/presentation/login_page/widgets/auth_gate_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: kIsWeb
            ? SizedBox(
                width: 500,
                child: Image.asset(
                  'assets/images/splash.gif',
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                'assets/images/splash.gif',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }
}

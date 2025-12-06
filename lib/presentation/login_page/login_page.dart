import 'package:apg_scanner/presentation/login_page/widgets/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/background.png",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 200.h),
              width: 350.w,
              height: 400.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                color: Colors.white.withValues(alpha: 0.4),
              ),
              child: LogInWidget(
                title: " APG Stock Taking",
                emailController: emailController,
                passwordController: passwordController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

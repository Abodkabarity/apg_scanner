import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/presentation/add_project/add_project_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'login_textfield.dart';

class LogInWidget extends StatelessWidget {
  const LogInWidget({
    super.key,
    required this.title,
    required this.emailController,
    required this.passwordController,
  });
  final String title;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 15.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 35.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 50.h),
          LoginTextField(
            label: 'Email',
            isObscure: false,
            controller: emailController,
            icon: Icons.email,
          ),
          LoginTextField(
            label: 'Password',
            isObscure: true,
            controller: passwordController,
            icon: Icons.lock,
          ),
          SizedBox(height: 40.h),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
              borderRadius: BorderRadius.circular(30.r),
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,

                colors: [AppColor.primaryColor, AppColor.secondaryColor],
              ),
            ),
            child: MaterialButton(
              minWidth: 300.w,
              height: 50.h,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AddProjectPage()),
                );
              },
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 25.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'login_textfield.dart';

class LogInWidget extends StatelessWidget {
  const LogInWidget({
    super.key,
    required this.title,
    required this.emailController,
    required this.passwordController,
    required this.onPressed,
    required this.error,
    required this.formKey,
    required this.onCheckBoxChanged,
    required this.isObscure,
  });
  final String title;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final void Function() onPressed;
  final String? error;
  final GlobalKey formKey;
  final void Function(bool?) onCheckBoxChanged;
  final bool isObscure;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
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
              validator: (value) {
                if (value == null || value.isEmpty) return "Email is required";

                bool valid = RegExp(
                  r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                ).hasMatch(value);

                if (!valid) return "Please enter a valid email";
              },
              errorText: error,
            ),
            LoginTextField(
              label: 'Password',
              isObscure: !isObscure,
              controller: passwordController,
              icon: Icons.lock,

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Password is required";
                }
              },
              errorText: error,
            ),

            CheckboxListTile(
              value: isObscure,
              activeColor: AppColor.secondaryColor,
              title: Padding(
                padding: EdgeInsets.only(left: 20.w),
                child: Text(
                  "Show Password",
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),

              onChanged: onCheckBoxChanged,
            ),
            SizedBox(height: 20.h),
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
                onPressed: onPressed,
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
      ),
    );
  }
}

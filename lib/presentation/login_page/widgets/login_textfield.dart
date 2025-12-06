import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.isObscure,
    required this.controller,
    required this.icon,
  });
  final String label;
  final bool isObscure;
  final TextEditingController controller;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 15.w),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          suffixIcon: Icon(icon),
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
      ),
    );
  }
}

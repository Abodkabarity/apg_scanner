import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';

class SubmitButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final void Function()? onPressed;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: AppColor.secondaryColor,
                ),
              ),
            ),
          ),
          if (icon != null)
            Icon(icon, color: AppColor.secondaryColor, size: 25),
        ],
      ),
    );
  }
}

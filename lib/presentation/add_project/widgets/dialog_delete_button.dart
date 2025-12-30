import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';

class DialogDeleteButton extends StatelessWidget {
  const DialogDeleteButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.color,
  });
  final void Function() onPressed;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColor.secondaryColor,
          fontSize: 16.sp,
        ),
      ),
    );
  }
}

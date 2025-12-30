import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';

class AddProjectDialog extends StatelessWidget {
  const AddProjectDialog({
    super.key,
    required this.projectController,
    required this.onPressed,
  });

  final TextEditingController projectController;
  final void Function() onPressed;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Add New Project",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: AppColor.secondaryColor,
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: projectController,
            decoration: InputDecoration(
              labelText: "Add New Project",
              labelStyle: TextStyle(color: AppColor.secondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.primaryColor),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(height: 10.h),
          MaterialButton(
            onPressed: onPressed,
            color: AppColor.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.r),
            ),
            minWidth: 150.w,
            child: Text(
              "Add",
              style: TextStyle(color: AppColor.secondaryColor, fontSize: 18.sp),
            ),
          ),
        ],
      ),
    );
  }
}

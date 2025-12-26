import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../near_expiry_bloc/near_expiry_bloc.dart';
import '../near_expiry_bloc/near_expiry_event.dart';

class NearExpiryExportBottomSheet extends StatelessWidget {
  final String projectId;
  final String projectName;
  final String branchName;

  const NearExpiryExportBottomSheet({
    super.key,
    required this.projectId,
    required this.branchName,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350.w,
      height: 300.h,
      child: Column(
        children: [
          SizedBox(height: 20.h),

          Text(
            "Export Near Expiry",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- SEND BY EMAIL ----------------
          SizedBox(
            width: 250.w,
            height: 50.h,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.email,
                color: AppColor.secondaryColor,
                size: 20,
              ),
              label: Text(
                "Send via Email",
                style: TextStyle(
                  color: AppColor.secondaryColor,
                  fontSize: 17.sp,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);

                context.read<NearExpiryBloc>().add(
                  SendByEmailEvent(
                    projectId: projectId,
                    branchName: branchName,
                    projectName: projectName,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20.h),

          // ---------------- SAVE ON DEVICE ----------------
          SizedBox(
            width: 250.w,
            height: 50.h,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.save,
                color: AppColor.secondaryColor,
                size: 20,
              ),
              label: Text(
                "Save on Device",
                style: TextStyle(
                  color: AppColor.secondaryColor,
                  fontSize: 17.sp,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);

                context.read<NearExpiryBloc>().add(
                  ExportExcelEvent(projectId, projectName: projectName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

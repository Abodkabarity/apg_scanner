import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../stock_taking_bloc/stock_taking_bloc.dart';
import '../stock_taking_bloc/stock_taking_event.dart';

class ExportBottomSheet extends StatelessWidget {
  final String projectId;
  final String branchName;
  const ExportBottomSheet({
    super.key,
    required this.projectId,
    required this.branchName,
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
            "Export Stock Taking",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

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
              onPressed: () async {
                Navigator.pop(context);

                context.read<StockBloc>().add(
                  SendStockByEmailEvent(
                    projectId: projectId,
                    branchName: branchName,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 20.h),

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
              onPressed: () async {
                Navigator.pop(context);

                context.read<StockBloc>().add(ExportExcelEvent(projectId));
              },
            ),
          ),
        ],
      ),
    );
  }
}

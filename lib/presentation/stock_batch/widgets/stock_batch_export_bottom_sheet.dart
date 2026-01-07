import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../stock_batch_bloc/stock_batch_bloc.dart';
import '../stock_batch_bloc/stock_batch_event.dart';

class StockBatchExportBottomSheet extends StatelessWidget {
  final String projectId;
  final String projectName;

  const StockBatchExportBottomSheet({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350.w,
      height: 260.h,
      child: Column(
        children: [
          SizedBox(height: 20.h),

          Text(
            "Export Stock Batch",
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 25.h),

          // ---------------- SEND BY EMAIL ----------------
          SizedBox(
            width: 250.w,
            height: 50.h,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.email, color: AppColor.secondaryColor),
              label: Text(
                "Send via Email",
                style: TextStyle(
                  color: AppColor.secondaryColor,
                  fontSize: 16.sp,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);

                context.read<StockBatchBloc>().add(
                  SendStockBatchByEmailEvent(
                    projectId: projectId,
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
              icon: const Icon(Icons.save, color: AppColor.secondaryColor),
              label: Text(
                "Save on Device",
                style: TextStyle(
                  color: AppColor.secondaryColor,
                  fontSize: 16.sp,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);

                context.read<StockBatchBloc>().add(
                  ExportStockBatchExcelEvent(
                    projectId: projectId,
                    projectName: projectName,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/services/stock_export_service.dart';

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
                final messenger = ScaffoldMessenger.of(context);

                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sending email...")),
                  );

                  final exportService = getIt<StockExportService>();
                  final branchRepo = getIt<BranchRepository>();

                  final branchEmail = await branchRepo.getEmailByBranchName(
                    branchName,
                  );

                  if (branchEmail == null || branchEmail.isEmpty) {
                    throw Exception("Branch email not found for $projectId");
                  }

                  await exportService.sendExcelByEmail(
                    projectId: projectId,
                    toEmail: branchEmail,
                  );

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("Email sent to $branchEmail ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("Failed to send email: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
                final service = getIt<StockExportService>();
                final messenger = ScaffoldMessenger.of(context);

                await service.exportAndSaveExcel(projectId);

                if (!context.mounted) return;

                Navigator.pop(context);

                messenger.showSnackBar(
                  const SnackBar(content: Text("Excel file saved on device")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:apg_scanner/presentation/add_project/add_project_page.dart';
import 'package:apg_scanner/presentation/widgets/background_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_color/app_color.dart';
import '../../core/app_images/app_images.dart';
import '../../core/constant/project_type.dart';
import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../../data/repositories/project_repository.dart';
import '../add_project/project_bloc/project_bloc.dart';
import '../add_project/project_bloc/project_event.dart';
import '../login_page/widgets/auth_gate_widget.dart';

class SelectProjectPage extends StatelessWidget {
  const SelectProjectPage({super.key});
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColor.secondaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: AppColor.secondaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();
    getIt<UserSession>().clear();
    getIt<ProjectRepository>().clearCache();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Projects",
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset(AppImages.logo, fit: BoxFit.cover),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: IconButton(
              onPressed: () async {
                await _logout(context);
              },
              icon: Icon(Icons.login_outlined, color: Colors.white, size: 30),
            ),
          ),
        ],
        backgroundColor: AppColor.primaryColor,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          BackGroundWidget(),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 50.h),
              child: Column(
                children: [
                  RawMaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return AddProjectPage(
                              projectType: ProjectType.stockTaking,
                            );
                          },
                        ),
                      );
                      context.read<ProjectBloc>().add(
                        LoadProjectsEvent(ProjectType.stockTaking),
                      );
                    },

                    fillColor: AppColor.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: AppColor.secondaryColor),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 300.w,
                      minHeight: 75.h,
                    ),
                    elevation: 10,
                    child: Text(
                      "Stock Taking",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColor.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
                  RawMaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return AddProjectPage(
                              projectType: ProjectType.nearExpiry,
                            );
                          },
                        ),
                      );
                      context.read<ProjectBloc>().add(
                        LoadProjectsEvent(ProjectType.nearExpiry),
                      );
                    },

                    fillColor: AppColor.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: AppColor.secondaryColor),
                    ),
                    elevation: 10,

                    constraints: BoxConstraints(
                      minWidth: 300.w,
                      minHeight: 75.h,
                    ),

                    child: Text(
                      "Near Expiry",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColor.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

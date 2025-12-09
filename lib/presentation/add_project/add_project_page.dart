import 'package:apg_scanner/presentation/add_project/project_bloc/project_bloc.dart';
import 'package:apg_scanner/presentation/add_project/project_bloc/project_event.dart';
import 'package:apg_scanner/presentation/add_project/project_bloc/project_state.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_page.dart';
import 'package:apg_scanner/presentation/widgets/background_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../../core/app_images/app_images.dart';

class AddProjectPage extends StatelessWidget {
  AddProjectPage({super.key});
  final TextEditingController projectController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Projects",
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset(AppImages.logo, fit: BoxFit.cover),
        ),
        backgroundColor: AppColor.primaryColor,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          BackGroundWidget(),
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.projects.length,
                      itemBuilder: (context, i) => ListProjectWidget(
                        projectName: state.projects[i].name,
                        id: "${state.projects[i].id}",
                        onDelete: () {},
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 200.h),
                    child: MaterialButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
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
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.r),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                SizedBox(height: 10.h),
                                MaterialButton(
                                  onPressed: () {
                                    dialogContext.read<ProjectBloc>().add(
                                      CreateProjectEvent(
                                        projectController.text.trim(),
                                      ),
                                    );

                                    // print(projectController.text);
                                    print(state.projects);
                                    Navigator.pop(context);
                                  },
                                  color: AppColor.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  minWidth: 150.w,
                                  child: Text(
                                    "Add",
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      minWidth: 200.w,
                      height: 50.h,
                      color: AppColor.primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: AppColor.secondaryColor),
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Add Project",
                            style: TextStyle(
                              color: AppColor.secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Icon(Icons.add, size: 25),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ListProjectWidget extends StatelessWidget {
  const ListProjectWidget({
    super.key,
    required this.projectName,
    required this.id,
    required this.onDelete,
  });
  final String projectName;
  final String id;
  final void Function() onDelete;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          projectName,
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Text(id, style: TextStyle(color: AppColor.secondaryColor)),
        trailing: IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete, color: AppColor.secondaryColor),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StockTakingPage()),
          );
        },
      ),
    );
  }
}

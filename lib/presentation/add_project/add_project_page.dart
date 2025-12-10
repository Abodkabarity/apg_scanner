import 'package:apg_scanner/data/model/project_model.dart';
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
import '../../core/di/injection.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_taking_repository.dart';
import '../stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import '../stock_taking/stock_taking_bloc/stock_taking_event.dart';

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

      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state.createSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => StockBloc(
                      getIt<StockRepository>(),
                      getIt<ProductsRepository>(),
                    )..add(LoadStockEvent(state.projects.last.id)),
                    child: StockTakingPage(projects: state.projects.last),
                  ),
                ),
              );
            });
          }
        },
        child: Stack(
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
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Are you sure to delete ${state.projects[i].name} project?",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: AppColor.secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DialogDeleteButton(
                                            onPressed: () {
                                              dialogContext
                                                  .read<ProjectBloc>()
                                                  .add(
                                                    DeleteProjectEvent(
                                                      state.projects[i].id,
                                                    ),
                                                  );
                                              dialogContext
                                                  .read<ProjectBloc>()
                                                  .add(LoadProjectsEvent());
                                              Navigator.pop(dialogContext);
                                            },
                                            label: "Yes",
                                            color: Colors.red,
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        Expanded(
                                          child: DialogDeleteButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext);
                                            },
                                            label: "No",
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          projects: state.projects[i],
                        ),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        final list = await getIt<ProductsRepository>()
                            .getAllLocal();
                        print("LOCAL PRODUCTS = ${list.length}");
                      },
                      child: Text("Test"),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 200.h),
                      child: MaterialButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AddProjectDialog(
                              projectController: projectController,
                              onPressed: () async {
                                if (projectController.text.isNotEmpty) {
                                  dialogContext.read<ProjectBloc>().add(
                                    CreateProjectEvent(
                                      projectController.text.trim(),
                                    ),
                                  );
                                }

                                Navigator.pop(dialogContext);
                                projectController.clear();
                              },
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
      ),
    );
  }
}

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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
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

class ListProjectWidget extends StatelessWidget {
  const ListProjectWidget({
    super.key,
    required this.projectName,
    required this.onDelete,
    required this.projects,
  });
  final String projectName;
  final ProjectModel projects;

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
        leading: Icon(Icons.folder, color: AppColor.secondaryColor),
        trailing: IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete, color: AppColor.secondaryColor),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => StockBloc(
                  getIt<StockRepository>(),
                  getIt<ProductsRepository>(),
                )..add(LoadStockEvent(projects.id.toString())),
                child: StockTakingPage(projects: projects),
              ),
            ),
          );
        },
      ),
    );
  }
}

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

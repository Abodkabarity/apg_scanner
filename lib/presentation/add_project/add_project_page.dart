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
import '../../core/constant/project_type.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/near_expiry_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_taking_repository.dart';
import '../near_expiry/near_expiry_bloc/near_expiry_bloc.dart';
import '../near_expiry/near_expiry_bloc/near_expiry_event.dart';
import '../near_expiry/near_expiry_page.dart';
import '../stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import '../stock_taking/stock_taking_bloc/stock_taking_event.dart';

class AddProjectPage extends StatelessWidget {
  final ProjectType projectType;

  AddProjectPage({super.key, required this.projectType});
  final TextEditingController projectController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectType == ProjectType.stockTaking
              ? "Stock Taking Project"
              : "Near Expiry Project",
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(AppImages.logo, fit: BoxFit.cover),
          ),
        ],
        backgroundColor: AppColor.primaryColor,
        centerTitle: true,
      ),

      body: BlocListener<ProjectBloc, ProjectState>(
        listenWhen: (prev, curr) => prev.createSuccess != curr.createSuccess,
        listener: (context, state) {
          if (state.createSuccess && state.project != null) {
            final project = state.project!;

            if (projectType == ProjectType.stockTaking) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => StockBloc(
                      getIt<StockRepository>(),
                      getIt<ProductsRepository>(),
                    )..add(LoadStockEvent(project.id.toString())),
                    child: StockTakingPage(projects: project),
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => NearExpiryBloc(
                      getIt<NearExpiryRepository>(),
                      getIt<ProductsRepository>(),
                    )..add(LoadNearExpiryEvent(project.id.toString())),
                    child: NearExpiryPage(projects: project),
                  ),
                ),
              );
            }
          }
        },

        child: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            return Stack(
              children: [
                BackGroundWidget(),
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        key: ValueKey(state.projects.map((e) => e.id).join()),

                        itemCount: state.projects.length,
                        itemBuilder: (context, i) => ListProjectWidget(
                          projectName: state.projects[i].name,
                          projects: state.projects[i],
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
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogContext),
                                            child: const Text(
                                              "Cancel",
                                              style: TextStyle(
                                                color: AppColor.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              context.read<ProjectBloc>().add(
                                                DeleteProjectEvent(
                                                  state.projects[i].id,
                                                  projectType,
                                                ),
                                              );

                                              Navigator.pop(dialogContext);
                                            },
                                            child: Text(
                                              "Yes",
                                              style: TextStyle(
                                                color: AppColor.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          projectType: projectType,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(bottom: 200.h),
                      child: MaterialButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddProjectDialog(
                              projectController: projectController,
                              onPressed: () {
                                if (projectController.text.isNotEmpty) {
                                  context.read<ProjectBloc>().add(
                                    CreateProjectEvent(
                                      projectController.text.trim(),
                                      projectType,
                                    ),
                                  );
                                }
                                Navigator.pop(context);
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
                            Icon(Icons.add),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
    required this.projectType,
  });
  final String projectName;
  final ProjectModel projects;
  final ProjectType projectType;

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
          if (projectType == ProjectType.stockTaking) {
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
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => NearExpiryBloc(
                    getIt<NearExpiryRepository>(),
                    getIt<ProductsRepository>(),
                  )..add(LoadNearExpiryEvent(projects.id.toString())),
                  child: NearExpiryPage(projects: projects),
                ),
              ),
            );
          }
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

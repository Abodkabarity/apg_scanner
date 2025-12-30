import 'package:apg_scanner/presentation/add_project/project_bloc/project_bloc.dart';
import 'package:apg_scanner/presentation/add_project/project_bloc/project_event.dart';
import 'package:apg_scanner/presentation/add_project/project_bloc/project_state.dart';
import 'package:apg_scanner/presentation/add_project/widgets/add_project_dialog.dart';
import 'package:apg_scanner/presentation/add_project/widgets/list_project_widget.dart';
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
                            barrierDismissible: false,
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

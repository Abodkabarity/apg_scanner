import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/constant/project_type.dart';
import '../../../core/di/injection.dart';
import '../../../data/model/project_model.dart';
import '../../../data/repositories/near_expiry_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/stock_taking_repository.dart';
import '../../near_expiry/near_expiry_bloc/near_expiry_bloc.dart';
import '../../near_expiry/near_expiry_bloc/near_expiry_event.dart';
import '../../near_expiry/near_expiry_page.dart';
import '../../stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import '../../stock_taking/stock_taking_bloc/stock_taking_event.dart';
import '../../stock_taking/stock_taking_page.dart';

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

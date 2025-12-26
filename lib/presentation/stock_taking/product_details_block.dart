import 'package:apg_scanner/data/model/project_model.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/dropdown_type_unit.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/stock_taking_repository.dart';
import '../widgets/top_snackbar.dart';

class ProductDetailsBlock extends StatelessWidget {
  const ProductDetailsBlock({
    super.key,
    required this.nameController,
    required this.qtyController,
    required this.scanController,
    required this.projects,
    required this.qtyFocusNode,
  });
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController scanController;
  final FocusNode qtyFocusNode;

  final ProjectModel projects;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        color: const Color(0x1a4eb0de),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            readOnly: true,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              labelText: "Name",
              labelStyle: TextStyle(color: AppColor.secondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColor.primaryColor),
              ),
            ),
          ),
          SizedBox(height: 30.h),

          Row(
            children: [
              const Expanded(child: DropDownUnitType()),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  focusNode: qtyFocusNode,
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: "Quantity",

                    labelStyle: TextStyle(color: AppColor.secondaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColor.primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColor.primaryColor),
                    ),
                  ),
                  onEditingComplete: () {
                    qtyFocusNode.unfocus();
                  },
                  onSubmitted: (_) {
                    qtyFocusNode.unfocus();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 25.h),

          SizedBox(
            width: 250.w,
            height: 40.h,
            child: SubmitButton(
              label: "Approve",
              icon: Icons.done,
              onPressed: () {
                getIt<StockRepository>().debugPrintAll(projects.id);
                final unit = context.read<StockBloc>().state.selectedUnit;
                final qty = int.tryParse(qtyController.text) ?? 0;

                if (unit == null || qty <= 0) {
                  showTopSnackBar(
                    context,
                    message: "Unit & Quantity required",
                    backgroundColor: Colors.red.shade700,
                    icon: Icons.warning_amber_rounded,
                  );

                  return;
                }

                context.read<StockBloc>().add(
                  ApproveItemEvent(
                    projectId: projects.id.toString(),
                    barcode: scanController.text,
                    unit: unit,
                    qty: qty,
                    projectName: projects.name.toString(),
                  ),
                );
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

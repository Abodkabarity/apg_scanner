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

class ProductDetailsBlock extends StatelessWidget {
  const ProductDetailsBlock({
    super.key,
    required this.nameController,
    required this.qtyController,
    required this.scanController,
    required this.projects,
  });
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController scanController;
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
          ),
          SizedBox(height: 30.h),

          Row(
            children: [
              const Expanded(flex: 2, child: DropDownUnitType()),
              SizedBox(width: 10.w),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: "Quantity",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 25.h),

          Row(
            children: [
              Expanded(
                child: SubmitButton(
                  label: "Approve",
                  icon: Icons.done,
                  onPressed: () {
                    getIt<StockRepository>().debugPrintAll(projects.id);
                    final unit = context.read<StockBloc>().state.selectedUnit;
                    final qty = int.tryParse(qtyController.text) ?? 0;

                    if (unit == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Unit & Quantity required"),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      return;
                    }

                    context.read<StockBloc>().add(
                      ApproveItemEvent(
                        projectId: projects.id.toString(),
                        barcode: scanController.text,
                        unit: unit,
                        qty: qty,
                      ),
                    );
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SubmitButton(
                  label: 'Delete',
                  icon: Icons.delete,

                  onPressed: () {
                    final bloc = context.read<StockBloc>();
                    final index = bloc.state.selectedIndex;

                    if (index == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select an item to delete"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final item = bloc.state.items[index];

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text(
                          "Delete Item",
                          style: TextStyle(color: AppColor.secondaryColor),
                        ),
                        content: Text(
                          "Are you sure you want to delete\n${item.itemName} ?",
                          style: const TextStyle(
                            color: AppColor.secondaryColor,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            child: const Text("Delete"),
                            onPressed: () {
                              bloc.add(DeleteStockEvent(item.id));
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

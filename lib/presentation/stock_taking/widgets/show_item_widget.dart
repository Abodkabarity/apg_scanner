import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import 'multi_unit_dialog.dart';

class ShowItemsList extends StatelessWidget {
  const ShowItemsList({
    super.key,
    required this.projectId,
    required this.projectName,
    this.id,
  });
  final String? id;
  final String projectId;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0x1a4eb0de),
          ),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  context.read<StockBloc>().add(SearchScannedItemsEvent(value));
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  labelText: "Search Product Scanning",
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                height: 350.h,
                child: ListView.builder(
                  key: ValueKey(state.productsRevision),

                  itemCount: state.filteredGroupedItems.length,
                  itemBuilder: (context, i) {
                    final group = state.filteredGroupedItems[i];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          group.itemName,
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        leading: Text(
                          "Box",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                        trailing: Text(
                          "Qty ${group.totalSubQty!.toStringAsFixed(2)}",

                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        onTap: () async {
                          final bloc = context.read<StockBloc>();

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                "Edit Item",
                                style: TextStyle(
                                  color: AppColor.secondaryColor,
                                ),
                              ),
                              content: const Text(
                                "Do you want to edit this item?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text(
                                    "No",
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Yes",
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;

                          if (confirm != true) return;

                          final product = bloc.productsRepo.products.firstWhere(
                            (p) => p.itemCode == group.itemCode,
                          );

                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) => MultiUnitEditDialog(
                              group: group,
                              allUnits: bloc.productsRepo.getUnitsForProduct(
                                product,
                              ),
                              numberSubUnit: product.numberSubUnit.toInt(),
                              onApply: (newUnitQty) {
                                bloc.add(
                                  UpdateMultiUnitEvent(
                                    projectId: projectId,
                                    group: group,
                                    newUnitQty: newUnitQty,
                                    projectName: projectName,
                                  ),
                                );
                              },
                              onDelete: () {
                                bloc.add(
                                  DeleteStockEvent(
                                    projectId: projectId,
                                    ids: group.unitId.values.toList(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

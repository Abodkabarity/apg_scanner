import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import 'multi_unit_dialog.dart';

class ShowItemsList extends StatelessWidget {
  const ShowItemsList({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
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
                            fontSize: 15.sp,
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
                          "Qty ${group.totalSubQty.toStringAsFixed(2)}",

                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        onTap: () {
                          if (!group.isMultiUnit) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text(
                                  "Edit Item",
                                  style: TextStyle(
                                    color: AppColor.secondaryColor,
                                  ),
                                ),
                                content: const Text(
                                  "Do you want to edit this item?",
                                  style: TextStyle(
                                    color: AppColor.secondaryColor,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text(
                                      "No",
                                      style: TextStyle(
                                        color: AppColor.secondaryColor,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final unit = group.unitQty.keys.first;
                                      final qty = group.unitQty[unit] ?? 0;
                                      final rowId = group.unitId[unit]!;

                                      context.read<StockBloc>().add(
                                        EditSingleUnitFromListEvent(
                                          group: group,
                                          rowId: rowId,
                                          unit: unit,
                                          qty: qty,
                                        ),
                                      );

                                      Navigator.pop(dialogContext);
                                    },
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
                            return;
                          }
                          final bloc = context.read<StockBloc>();

                          final product = bloc.productsRepo.products.firstWhere(
                            (p) => p.itemCode == group.itemCode,
                          );
                          showDialog(
                            context: context,
                            builder: (_) => MultiUnitEditDialog(
                              group: group,
                              onApply: (newUnitQty) {
                                context.read<StockBloc>().add(
                                  UpdateMultiUnitEvent(
                                    projectId: projectId,

                                    group: group,
                                    newUnitQty: newUnitQty,
                                  ),
                                );
                              },
                              numberSubUnit: product.numberSubUnit,
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

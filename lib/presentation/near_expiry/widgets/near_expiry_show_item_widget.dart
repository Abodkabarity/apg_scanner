import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_item_group.dart';
import '../near_expiry_bloc/near_expiry_bloc.dart';
import '../near_expiry_bloc/near_expiry_event.dart';
import '../near_expiry_bloc/near_expiry_state.dart';
import 'near_expiry_multi_unit_dialog.dart';

class NearExpiryShowItemsList extends StatelessWidget {
  const NearExpiryShowItemsList({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;
  String _formatMonthYear(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    return '$m/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearExpiryBloc, NearExpiryState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0x1a4eb0de),
          ),
          child: Column(
            children: [
              // ---------------- Search ----------------
              TextField(
                onChanged: (value) {
                  context.read<NearExpiryBloc>().add(
                    SearchScannedItemsEvent(value),
                  );
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: AppColor.secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColor.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColor.primaryColor),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  labelText: "Search Scanned Products",
                ),
              ),

              SizedBox(height: 10.h),

              // ---------------- List ----------------
              SizedBox(
                height: 350.h,
                child: ListView.builder(
                  itemCount: state.filteredGroupedItems.length,
                  itemBuilder: (context, i) {
                    final StockItemGroup group = state.filteredGroupedItems[i];

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
                        subtitle: Text(
                          'Near Expiry: ${_formatMonthYear(group.nearExpiry!)}',
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                        trailing: Text(
                          "Qty ${group.totalSubQty.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                        leading: Text(
                          "Box",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        // ---------------- Edit / Delete ----------------
                        onTap: () async {
                          final bloc = context.read<NearExpiryBloc>();

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
                            orElse: () => throw Exception("Product not found"),
                          );

                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<NearExpiryBloc>(),
                              child: NearExpiryMultiUnitDialog(
                                group: group,

                                allUnits: bloc.productsRepo.getUnitsForProduct(
                                  product,
                                ),

                                numberSubUnit: product.numberSubUnit.toInt(),

                                onApply: (newUnitQty, newNearExpiry) {
                                  bloc.add(
                                    UpdateMultiUnitEvent(
                                      projectId: projectId,
                                      projectName: projectName,
                                      group: group,
                                      newUnitQty: newUnitQty,
                                      newNearExpiry: newNearExpiry,
                                    ),
                                  );
                                },

                                onDelete: () {
                                  bloc.add(
                                    DeleteNearExpiryEvent(
                                      projectId: projectId,
                                      ids: group.unitId.values.toList(),
                                    ),
                                  );
                                },
                              ),
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

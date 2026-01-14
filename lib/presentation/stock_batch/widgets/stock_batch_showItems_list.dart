import 'package:apg_scanner/presentation/stock_batch/widgets/stock_batch_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_batch_group.dart';
import '../stock_batch_bloc/stock_batch_bloc.dart';
import '../stock_batch_bloc/stock_batch_event.dart';
import '../stock_batch_bloc/stock_batch_state.dart';

class StockBatchShowItemsList extends StatelessWidget {
  const StockBatchShowItemsList({super.key, required this.projectId});

  final String projectId;

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    final m = d.month.toString().padLeft(2, '0');
    return '$m/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBatchBloc, StockBatchState>(
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
              // ---------------- SEARCH ----------------
              TextField(
                onChanged: (v) {
                  context.read<StockBatchBloc>().add(
                    SearchBatchQueryChanged(v),
                  );
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Search Scanned Products",
                  labelStyle: TextStyle(color: AppColor.secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColor.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: AppColor.primaryColor),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // ---------------- LIST ----------------
              SizedBox(
                height: 350.h,
                child: state.filteredGroupedItems.isEmpty
                    ? Center(
                        child: Text(
                          "No scanned items",
                          style: TextStyle(
                            color: AppColor.secondaryColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.filteredGroupedItems.length,
                        itemBuilder: (context, i) {
                          final StockBatchGroup group =
                              state.filteredGroupedItems[i];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              // ---------------- TITLE ----------------
                              title: Text(
                                group.itemName,
                                style: TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),

                              // ---------------- SUBTITLE ----------------
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Batch: ${group.batch}',
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    'Near Expiry: ${_fmt(group.nearExpiry)}',
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),

                              // ---------------- QTY ----------------
                              trailing: Text(
                                'Qty ${group.totalQty.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppColor.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                              onLongPress: () async {
                                final bloc = context.read<StockBatchBloc>();
                                final productsRepo = bloc.productsRepo;

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text("Edit Item"),
                                    content: const Text(
                                      "Do you want to edit this item?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogCtx).pop(false),
                                        child: const Text("No"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(dialogCtx).pop(true),
                                        child: const Text("Yes"),
                                      ),
                                    ],
                                  ),
                                );

                                if (!context.mounted) return;

                                if (confirm != true) return;

                                final product = productsRepo
                                    .searchLocal(
                                      (p) => p.itemCode == group.itemCode,
                                    )
                                    .first;

                                if (!context.mounted) return;

                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) => BlocProvider.value(
                                    value: bloc,
                                    child: StockBatchMultiUnitDialog(
                                      group: group,
                                      isBatch: product.isBatch,

                                      allUnits: productsRepo.getUnitsForProduct(
                                        product,
                                      ),
                                      subUnitQty:
                                          product.subunitQty?.toInt() ?? 1,

                                      initialUnitQty: Map<String, double>.from(
                                        group.unitQty,
                                      ),
                                      initialExpiry: group.nearExpiry,
                                      initialBatch: group.batch,

                                      onApply:
                                          (newUnitQty, newExpiry, newBatch) {
                                            bloc.add(
                                              UpdateStockBatchItemEvent(
                                                projectId: projectId,
                                                group: group,
                                                newUnitQty: newUnitQty,
                                                newExpiry: newExpiry,
                                                newBatch: newBatch,
                                              ),
                                            );
                                          },

                                      onDelete: () {
                                        bloc.add(
                                          DeleteStockBatchGroupEvent(
                                            projectId: projectId,
                                            group: group,
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

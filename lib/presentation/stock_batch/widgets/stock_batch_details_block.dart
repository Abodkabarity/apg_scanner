import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/project_model.dart';
import '../../stock_taking/widgets/submit_button.dart';
import '../../widgets/top_snackbar.dart';
import '../stock_batch_bloc/stock_batch_bloc.dart';
import '../stock_batch_bloc/stock_batch_event.dart';
import '../stock_batch_bloc/stock_batch_state.dart';

class StockBatchDetailsBlock extends StatelessWidget {
  const StockBatchDetailsBlock({
    super.key,
    required this.project,
    required this.scanController,
    required this.nameController,
    required this.qtyController,
    required this.qtyFocusNode,
  });

  final ProjectModel project;
  final TextEditingController scanController;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final FocusNode qtyFocusNode;

  String _fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBatchBloc, StockBatchState>(
      builder: (context, state) {
        final bloc = context.read<StockBatchBloc>();
        final product = state.currentProduct;

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0x1a4eb0de),
          ),
          child: Column(
            children: [
              // ---------------- ITEM NAME ----------------
              TextField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Item Name",
                ),
              ),

              SizedBox(height: 10.h),

              // ---------------- BATCH FLOW (ANIMATED) ----------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: state.isBatch
                    ? Column(
                        key: const ValueKey('batch_on'),
                        children: [
                          DropdownButtonFormField2<DateTime>(
                            value:
                                state.expiryOptions.contains(
                                  state.selectedExpiry,
                                )
                                ? state.selectedExpiry
                                : null,
                            items: state.expiryOptions
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(_fmt(d)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                bloc.add(
                                  ChangeSelectedExpiryEvent(
                                    itemCode: product!.itemCode,
                                    expiry: v,
                                  ),
                                );
                              }
                            },
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Near Expiry",
                            ),
                          ),

                          SizedBox(height: 10.h),

                          DropdownButtonFormField2<String>(
                            value:
                                state.batchOptions.contains(state.selectedBatch)
                                ? state.selectedBatch
                                : null,
                            items: state.batchOptions
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                            onChanged: state.batchOptions.isEmpty
                                ? null
                                : (v) {
                                    if (v != null) {
                                      bloc.add(ChangeSelectedBatchEvent(v));
                                    }
                                  },
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Batch",
                            ),
                          ),

                          SizedBox(height: 10.h),
                        ],
                      )
                    : const SizedBox(key: ValueKey('batch_off')),
              ),

              // ---------------- UNIT ----------------
              DropdownButtonFormField2<String>(
                value: state.units.contains(state.selectedUnit)
                    ? state.selectedUnit
                    : null,
                items: state.units
                    .map(
                      (u) => DropdownMenuItem<String>(value: u, child: Text(u)),
                    )
                    .toList(),
                onChanged: state.units.isEmpty
                    ? null
                    : (v) {
                        if (v != null) {
                          bloc.add(ChangeUnitEvent(v));
                        }
                      },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Unit",
                ),
              ),

              SizedBox(height: 10.h),

              // ---------------- QTY ----------------
              TextField(
                controller: qtyController,
                focusNode: qtyFocusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Quantity",
                ),
              ),

              SizedBox(height: 15.h),

              // ---------------- APPROVE ----------------
              SizedBox(
                width: 220.w,
                height: 40.h,
                child: SubmitButton(
                  label: "Approve",
                  icon: Icons.done,
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text.trim()) ?? 0;

                    if (state.currentProduct == null) {
                      showTopSnackBar(
                        context,
                        message: "Select item first",
                        backgroundColor: Colors.orange,
                        icon: Icons.info,
                      );
                      return;
                    }

                    if (state.isBatch && state.selectedExpiry == null) {
                      showTopSnackBar(
                        context,
                        message: "Near expiry required",
                        backgroundColor: Colors.orange,
                        icon: Icons.info,
                      );
                      return;
                    }

                    if (state.isBatch &&
                        (state.selectedBatch == null ||
                            state.selectedBatch!.isEmpty)) {
                      showTopSnackBar(
                        context,
                        message: "Batch required",
                        backgroundColor: Colors.orange,
                        icon: Icons.info,
                      );
                      return;
                    }

                    if (state.selectedUnit == null) {
                      showTopSnackBar(
                        context,
                        message: "Unit required",
                        backgroundColor: Colors.orange,
                        icon: Icons.info,
                      );
                      return;
                    }

                    if (qty <= 0) {
                      showTopSnackBar(
                        context,
                        message: "Quantity required",
                        backgroundColor: Colors.orange,
                        icon: Icons.info,
                      );
                      return;
                    }

                    bloc.add(
                      ApproveBatchItemEvent(
                        projectId: project.id.toString(),
                        projectName: project.name,
                        barcode: scanController.text.trim(),
                        unit: state.selectedUnit!,
                        qty: qty,
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

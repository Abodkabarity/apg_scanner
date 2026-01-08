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

  // 🔑 Sentinel values
  static final DateTime _otherExpiry = DateTime(1900, 1, 1);
  static const String _otherBatch = '__OTHER__';

  String _fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBatchBloc, StockBatchState>(
      builder: (context, state) {
        final bloc = context.read<StockBatchBloc>();
        final product = state.currentProduct;

        final allExpiryOptions = [
          ...state.expiryOptions,
          if (state.manualExpiry != null &&
              !state.expiryOptions.contains(state.manualExpiry))
            state.manualExpiry!,
        ];

        final allBatchOptions = [
          ...state.batchOptions,
          if (state.manualBatch != null &&
              !state.batchOptions.contains(state.manualBatch))
            state.manualBatch!,
        ];

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

              // ---------------- BATCH FLOW ----------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: state.isBatch
                    ? Column(
                        key: const ValueKey('batch_on'),
                        children: [
                          // ---------------- NEAR EXPIRY ----------------
                          DropdownButtonFormField2<DateTime>(
                            value:
                                allExpiryOptions.contains(state.selectedExpiry)
                                ? state.selectedExpiry
                                : null,
                            items: [
                              ...allExpiryOptions.map(
                                (d) => DropdownMenuItem<DateTime>(
                                  value: d,
                                  child: Text(_fmt(d)),
                                ),
                              ),
                              DropdownMenuItem<DateTime>(
                                key: ValueKey(
                                  '${state.currentProduct?.itemCode ?? 'no_product'}_expiry',
                                ),
                                value: _otherExpiry,
                                child: const Text(
                                  'Other (Select manually)',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;

                              if (v != _otherExpiry) {
                                bloc.add(
                                  ChangeSelectedExpiryEvent(
                                    itemCode: product!.itemCode,
                                    expiry: v,
                                    isManual: true,
                                  ),
                                );
                                return;
                              }

                              // ---- OTHER ----
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: DateTime.now(),
                              );

                              if (picked != null) {
                                final expiry = DateTime(
                                  picked.year,
                                  picked.month,
                                  1,
                                );

                                bloc.add(
                                  ChangeSelectedExpiryEvent(
                                    itemCode: product!.itemCode,
                                    expiry: expiry,
                                    isManual: true,
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

                          // ---------------- BATCH ----------------
                          DropdownButtonFormField2<String>(
                            key: ValueKey(
                              '${state.currentProduct?.itemCode ?? 'no_product'}_batch',
                            ),
                            value: allBatchOptions.contains(state.selectedBatch)
                                ? state.selectedBatch
                                : null,
                            items: [
                              ...allBatchOptions.map(
                                (b) => DropdownMenuItem<String>(
                                  value: b,
                                  child: Text(b),
                                ),
                              ),
                              const DropdownMenuItem<String>(
                                value: _otherBatch,
                                child: Text(
                                  'Other (Enter manually)',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              final focusScope = FocusScope.of(context);

                              if (v != _otherBatch) {
                                bloc.add(ChangeSelectedBatchEvent(v));
                                focusScope.requestFocus(qtyFocusNode);

                                return;
                              }

                              // ---- OTHER ----
                              final controller = TextEditingController();

                              final result = await showDialog<String>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Enter Batch'),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Batch number',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(
                                        context,
                                        controller.text.trim(),
                                      ),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );

                              if (result != null && result.isNotEmpty) {
                                bloc.add(
                                  ChangeSelectedBatchEvent(
                                    result,
                                    isManual: true,
                                  ),
                                );
                                focusScope.requestFocus(qtyFocusNode);
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
                    : const SizedBox(),
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

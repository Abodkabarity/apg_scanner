import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/utils/text_input_formatter.dart';
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
    required this.scanFocusNode,
  });

  final ProjectModel project;
  final TextEditingController scanController;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final FocusNode qtyFocusNode;
  final FocusNode scanFocusNode;

  // 🔑 Sentinel values
  static final DateTime _otherExpiry = DateTime(1900, 1, 1);
  static const String _otherBatch = '__OTHER__';

  String _fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBatchBloc, StockBatchState>(
      listenWhen: (prev, curr) => prev.autoFocusQty != curr.autoFocusQty,
      listener: (context, state) {
        if (state.autoFocusQty) {
          FocusScope.of(context).requestFocus(qtyFocusNode);
          context.read<StockBatchBloc>().add(const ResetAutoFocusQtyEvent());
        }
      },
      child: BlocBuilder<StockBatchBloc, StockBatchState>(
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
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: "Item Name",
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
                                  allExpiryOptions.contains(
                                    state.selectedExpiry,
                                  )
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
                                    'Other',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
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

                                final picked = await showMonthYearPicker(
                                  context,
                                );

                                if (picked != null) {
                                  bloc.add(
                                    ChangeSelectedExpiryEvent(
                                      itemCode: product!.itemCode,
                                      expiry: picked, // already day = 1
                                      isManual: true,
                                    ),
                                  );
                                }

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
                              dropdownStyleData: DropdownStyleData(
                                width: 180.w,
                                maxHeight: 250.h,
                                elevation: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.white,
                                ),
                                offset: const Offset(0, -2),
                              ),

                              menuItemStyleData: MenuItemStyleData(
                                height: 45.h,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                              ),

                              decoration: InputDecoration(
                                labelText: "Expiry Date (MM/YYYY)",
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: AppColor.secondaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            // ---------------- BATCH ----------------
                            DropdownButtonFormField2<String>(
                              key: ValueKey(
                                '${state.currentProduct?.itemCode ?? 'no_product'}_batch',
                              ),
                              value:
                                  allBatchOptions.contains(state.selectedBatch)
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
                                    'Other',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
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

                                      textCapitalization:
                                          TextCapitalization.characters,
                                      inputFormatters: [
                                        UpperCaseTextFormatter(),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Batch number',
                                        labelText: "Enter Batch",

                                        labelStyle: TextStyle(
                                          color: AppColor.secondaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColor.primaryColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColor.primaryColor,
                                          ),
                                        ),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 18.sp,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(
                                          context,
                                          controller.text.trim(),
                                        ),
                                        child: Text(
                                          'OK',
                                          style: TextStyle(
                                            color: AppColor.secondaryColor,
                                            fontSize: 18.sp,
                                          ),
                                        ),
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
                              decoration: InputDecoration(
                                labelText: "Batch",
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: AppColor.secondaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                              ),

                              dropdownStyleData: DropdownStyleData(
                                width: 180.w,
                                maxHeight: 250.h,
                                elevation: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.white,
                                ),
                                offset: const Offset(0, -2),
                              ),

                              menuItemStyleData: MenuItemStyleData(
                                height: 45.h,
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                              ),
                            ),

                            SizedBox(height: 10.h),
                          ],
                        )
                      : const SizedBox(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField2<String>(
                        value: state.units.contains(state.selectedUnit)
                            ? state.selectedUnit
                            : null,
                        items: state.units
                            .map(
                              (u) => DropdownMenuItem<String>(
                                value: u,
                                child: Text(u),
                              ),
                            )
                            .toList(),
                        onChanged: state.units.isEmpty
                            ? null
                            : (v) {
                                if (v != null) {
                                  bloc.add(ChangeUnitEvent(v));
                                }
                              },
                        dropdownStyleData: DropdownStyleData(
                          width: 160.w,
                          maxHeight: 220.h,
                          elevation: 6,
                          offset: const Offset(0, -5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.white,
                          ),
                        ),

                        menuItemStyleData: MenuItemStyleData(
                          height: 42.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                        ),

                        decoration: InputDecoration(
                          labelText: "Unit Type",
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: TextStyle(color: AppColor.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 10.w),

                    // ---------------- QTY ----------------
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        focusNode: qtyFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],

                        onSubmitted: (_) {
                          final qty =
                              double.tryParse(qtyController.text.trim()) ?? 0;

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

                          FocusScope.of(context).unfocus();
                          qtyController.clear();

                          bloc.add(
                            ApproveBatchItemEvent(
                              projectId: project.id.toString(),
                              projectName: project.name,
                              barcode: scanController.text.trim(),
                              unit: state.selectedUnit!,
                              qty: qty,
                            ),
                          );
                          final focusScope = FocusScope.of(context);
                          focusScope.requestFocus(scanFocusNode);
                          scanController.clear();
                        },

                        decoration: InputDecoration(
                          labelText: "Quantity",
                          fillColor: Colors.white,
                          filled: true,
                          labelStyle: TextStyle(color: AppColor.secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ---------------- UNIT ----------------
                SizedBox(height: 15.h),

                // ---------------- APPROVE ----------------
                SizedBox(
                  width: 220.w,
                  height: 40.h,
                  child: SubmitButton(
                    label: "Approve",
                    icon: Icons.done,
                    onPressed: () {
                      final qty =
                          double.tryParse(qtyController.text.trim()) ?? 0;

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
                      qtyController.clear();

                      bloc.add(
                        ApproveBatchItemEvent(
                          projectId: project.id.toString(),
                          projectName: project.name,
                          barcode: scanController.text.trim(),
                          unit: state.selectedUnit!,
                          qty: qty,
                        ),
                      );
                      final focusScope = FocusScope.of(context);
                      focusScope.requestFocus(scanFocusNode);
                      scanController.clear();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<DateTime?> showMonthYearPicker(BuildContext context) async {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Expiry (MM / YYYY)'),
          content: Row(
            children: [
              // MONTH
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedMonth,
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text((i + 1).toString().padLeft(2, '0')),
                    ),
                  ),
                  onChanged: (v) => selectedMonth = v!,
                  decoration: const InputDecoration(labelText: 'Month'),
                ),
              ),
              const SizedBox(width: 12),
              // YEAR
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedYear,
                  items: List.generate(15, (i) {
                    final year = DateTime.now().year + i;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (v) => selectedYear = v!,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  DateTime(selectedYear, selectedMonth, 1), // ✅ day = 1
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

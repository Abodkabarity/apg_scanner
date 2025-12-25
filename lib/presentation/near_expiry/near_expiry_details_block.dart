import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/data/model/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/top_snackbar.dart';
import 'near_expiry_bloc/near_expiry_bloc.dart';
import 'near_expiry_bloc/near_expiry_event.dart';
import 'near_expiry_bloc/near_expiry_state.dart';

class NearExpiryDetailsBlock extends StatelessWidget {
  const NearExpiryDetailsBlock({
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

  String _formatMonthYear(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    return '$m/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearExpiryBloc, NearExpiryState>(
      buildWhen: (p, c) =>
          p.currentProduct != c.currentProduct ||
          p.units != c.units ||
          p.selectedUnit != c.selectedUnit ||
          p.selectedNearExpiry != c.selectedNearExpiry ||
          p.nearExpiryOptions != c.nearExpiryOptions ||
          p.loading != c.loading,
      builder: (context, state) {
        final bloc = context.read<NearExpiryBloc>();
        final product = state.currentProduct;
        final expiryOptions = state.nearExpiryOptions;

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            children: [
              // ---------------- Item Name ----------------
              TextField(
                controller: nameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // ---------------- Unit ----------------
              DropdownButtonFormField<String>(
                initialValue: state.selectedUnit,
                items: state.units
                    .map(
                      (u) => DropdownMenuItem<String>(value: u, child: Text(u)),
                    )
                    .toList(),
                onChanged: (v) => bloc.add(ChangeUnitEvent(v)),
                decoration: InputDecoration(
                  labelText: "Unit",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // ---------------- Near Expiry (MONTH / YEAR) ----------------
              DropdownButtonFormField<DateTime>(
                initialValue: state.selectedNearExpiry,
                items: expiryOptions
                    .map(
                      (d) => DropdownMenuItem<DateTime>(
                        value: d,
                        child: Text(_formatMonthYear(d)),
                      ),
                    )
                    .toList(),
                onChanged: expiryOptions.isEmpty
                    ? null
                    : (v) {
                        if (v == null) return;
                        bloc.add(ChangeNearExpiryDateEvent(v));
                      },
                decoration: InputDecoration(
                  labelText: "Near Expiry (MM/YYYY)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // ---------------- Quantity ----------------
              TextField(
                controller: qtyController,
                focusNode: qtyFocusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // ---------------- Save ----------------
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      side: BorderSide(color: AppColor.secondaryColor),
                    ),
                  ),
                  onPressed: state.loading
                      ? null
                      : () {
                          if (product == null) {
                            showTopSnackBar(
                              context,
                              message: "Scan product first",
                              backgroundColor: Colors.orange,
                              icon: Icons.info,
                            );
                            return;
                          }

                          final unit = state.selectedUnit;
                          final expiry = state.selectedNearExpiry;
                          final qty =
                              int.tryParse(qtyController.text.trim()) ?? 0;

                          if (unit == null || unit.isEmpty) {
                            showTopSnackBar(
                              context,
                              message: "Unit required",
                              backgroundColor: Colors.orange,
                              icon: Icons.info,
                            );
                            return;
                          }

                          if (expiry == null) {
                            showTopSnackBar(
                              context,
                              message: "Near expiry required",
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
                            ApproveItemEvent(
                              projectId: project.id.toString(),
                              projectName: project.name.toString(),
                              barcode: scanController.text.trim(),
                              unit: unit,
                              qty: qty,
                              nearExpiry: expiry,
                            ),
                          );
                        },
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: AppColor.secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

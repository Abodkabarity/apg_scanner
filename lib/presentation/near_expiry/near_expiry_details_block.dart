import 'package:apg_scanner/data/model/project_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../stock_taking/widgets/submit_button.dart';
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
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0x1a4eb0de),
          ),
          child: Column(
            children: [
              // ---------------- Item Name ----------------
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField2<String>(
                      value: state.selectedUnit,
                      isExpanded: true,

                      items: state.units
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u,
                              child: Text(
                                u,
                                style: TextStyle(
                                  color: AppColor.secondaryColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),

                      onChanged: (v) {
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
                          borderSide: BorderSide(color: AppColor.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColor.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      focusNode: qtyFocusNode,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        fillColor: Colors.white,
                        filled: true,
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
                  ),
                ],
              ),

              // ---------------- Unit ----------------
              SizedBox(height: 10.h),

              // ---------------- Near Expiry (MONTH / YEAR) ----------------
              DropdownButtonFormField2<DateTime>(
                value: state.selectedNearExpiry,
                isExpanded: true,

                items: expiryOptions
                    .map(
                      (d) => DropdownMenuItem<DateTime>(
                        value: d,
                        child: Text(
                          _formatMonthYear(d),
                          style: TextStyle(color: AppColor.secondaryColor),
                        ),
                      ),
                    )
                    .toList(),

                onChanged: expiryOptions.isEmpty
                    ? null
                    : (v) {
                        if (v != null) {
                          bloc.add(ChangeNearExpiryDateEvent(v));
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
                  labelText: "Near Expiry (MM/YYYY)",
                  filled: true,
                  fillColor: Colors.white,
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

              SizedBox(height: 15.h),

              // ---------------- Save ----------------
              SizedBox(
                width: 250.w,
                height: 40.h,
                child: SubmitButton(
                  label: "Approve",
                  icon: Icons.done,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

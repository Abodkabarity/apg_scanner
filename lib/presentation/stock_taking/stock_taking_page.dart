import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/core/app_images/app_images.dart';
import 'package:apg_scanner/data/model/project_model.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/barcode_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/di/injection.dart';
import '../../data/repositories/stock_taking_repository.dart';
import '../widgets/background_widget.dart';

class StockTakingPage extends StatelessWidget {
  StockTakingPage({super.key, required this.projects});
  final ProjectModel projects;
  final TextEditingController scanController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    print("Project name: ${projects.name}");
    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }

        if (state.success != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
              elevation: 10,
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.success!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          nameController.clear();
          scanController.clear();
          qtyController.clear();

          context.read<StockBloc>().add(ResetFormEvent());
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state.currentProduct != null && nameController.text.isEmpty) {
            nameController.text = state.currentProduct!.itemName;
          }
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Image.asset(AppImages.logo, fit: BoxFit.cover),
              ),
              title: Text(
                "Stock Taking App",
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.secondaryColor,
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColor.primaryColor,
            ),
            body: Stack(
              children: [
                BackGroundWidget(),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: Color(0x1a4eb0de),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 20.h,
                          ),
                          child: TextField(
                            controller: scanController,
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              labelText: "Scan Area",
                              labelStyle: TextStyle(
                                color: AppColor.secondaryColor,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.r),
                                borderSide: BorderSide(
                                  color: AppColor.primaryColor,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.scanner),
                                onPressed: () async {
                                  final barcode = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BarcodeScannerPage(),
                                    ),
                                  );

                                  if (barcode != null) {
                                    scanController.text = barcode;

                                    context.read<StockBloc>().add(
                                      ScanBarcodeEvent(
                                        projectId: projects.id.toString(),
                                        barcode: barcode,
                                      ),
                                    );
                                  }
                                  nameController.clear();
                                },
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColor.primaryColor,
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Container(
                        margin: EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: Color(0x1a4eb0de),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 20.h,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  labelText: "Name",
                                  labelStyle: TextStyle(
                                    color: AppColor.secondaryColor,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
                                  ),

                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                ),
                              ),
                              SizedBox(height: 30.h),
                              Row(
                                children: [
                                  Expanded(flex: 2, child: DropDownUnitType()),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: qtyController,
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        labelText: "Quantity",
                                        labelStyle: TextStyle(
                                          color: AppColor.secondaryColor,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColor.primaryColor,
                                          ),
                                        ),

                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColor.primaryColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25.r,
                                          ),
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
                                      onPressed: () {
                                        getIt<StockRepository>().debugPrintAll(
                                          projects.id,
                                        );

                                        final unit = context
                                            .read<StockBloc>()
                                            .state
                                            .selectedUnit;
                                        final qty =
                                            int.tryParse(qtyController.text) ??
                                            0;
                                        nameController.clear();

                                        if (unit == null || qty <= 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: const EdgeInsets.only(
                                                top: 10,
                                                left: 12,
                                                right: 12,
                                              ),
                                              elevation: 10,
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Expanded(
                                                    child: Text(
                                                      "Unit type and quantity required",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
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
                                      },

                                      icon: Icons.done,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: SubmitButton(
                                      label: 'Delete',
                                      onPressed: () {},
                                      icon: Icons.delete,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(
                          top: 100.h,
                          left: 50.w,
                          right: 50.w,
                        ),
                        child: SizedBox(
                          height: 60.h,
                          child: SubmitButton(
                            label: "Submit & Share",
                            onPressed: () {},
                            icon: Icons.save_alt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DropDownUnitType extends StatelessWidget {
  const DropDownUnitType({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockBloc, StockState>(
      builder: (context, state) {
        final units = state.units;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: BoxBorder.all(color: AppColor.secondaryColor),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: DropdownButton<String>(
              value: state.selectedUnit,
              isExpanded: true,

              focusColor: AppColor.primaryColor,
              underline: SizedBox(),
              hint: Text(
                "Unit Type",
                style: TextStyle(color: AppColor.secondaryColor),
              ),
              selectedItemBuilder: (context) {
                return units.map((e) {
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          e,
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },

              iconSize: 25,
              items: units.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),

              onChanged: (value) {
                if (value != null) {
                  context.read<StockBloc>().add(ChangeUnitEvent(value));
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final void Function()? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        foregroundColor: AppColor.secondaryColor,
        shadowColor: AppColor.primaryColor,
        elevation: 10,
        side: BorderSide(color: AppColor.secondaryColor),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          Expanded(child: Icon(icon, color: AppColor.secondaryColor, size: 25)),
        ],
      ),
    );
  }
}

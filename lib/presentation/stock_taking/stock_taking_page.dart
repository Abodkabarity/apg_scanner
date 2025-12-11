import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/core/app_images/app_images.dart';
import 'package:apg_scanner/data/model/products_model.dart';
import 'package:apg_scanner/data/model/project_model.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/barcode_scanner_page.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/search_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/background_widget.dart';

class StockTakingPage extends StatelessWidget {
  StockTakingPage({super.key, required this.projects});
  final ProjectModel projects;

  final TextEditingController scanController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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

          scanController.clear();
          nameController.clear();
          qtyController.clear();
          context.read<StockBloc>().add(ResetFormEvent());
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state.success == null && state.currentProduct != null) {
            nameController.text = state.currentProduct!.itemName;
          } else if (state.currentProduct == null) {
            nameController.clear();
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
                      // ----------------- SCAN + SEARCH -----------------
                      Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: const Color(0x1a4eb0de),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: scanController,
                              onChanged: (value) {
                                context.read<StockBloc>().add(
                                  SearchQueryChanged(value),
                                );
                              },
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                labelText: "Scan or Search Product",
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () async {
                                        final suggestions = context
                                            .read<StockBloc>()
                                            .state
                                            .suggestions;

                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SearchResultsPage(
                                              results: suggestions,
                                            ),
                                          ),
                                        );

                                        if (result is ProductModel) {
                                          context.read<StockBloc>().add(
                                            ProductChosenFromSearch(result),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.scanner),
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
                                      },
                                    ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                              ),
                            ),

                            // ---------------- Suggestions ----------------
                            if (state.suggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: state.suggestions.map((p) {
                                    return ListTile(
                                      title: Text(p.itemName),
                                      subtitle: Text(p.itemCode),
                                      onTap: () {
                                        context.read<StockBloc>().add(
                                          ProductChosenFromSearch(p),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ----------------- PRODUCT DETAILS -----------------
                      Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: const Color(0x1a4eb0de),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              readOnly: true,
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                labelText: "Name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 30.h),

                            Row(
                              children: [
                                const Expanded(
                                  flex: 2,
                                  child: DropDownUnitType(),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: qtyController,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: "Quantity",
                                      border: OutlineInputBorder(
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
                                    icon: Icons.done,
                                    onPressed: () {
                                      /* getIt<StockRepository>().debugPrintAll(
                                        projects.id,
                                      );*/
                                      final unit = context
                                          .read<StockBloc>()
                                          .state
                                          .selectedUnit;
                                      final qty =
                                          int.tryParse(qtyController.text) ?? 0;

                                      if (unit == null || qty <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Unit & Quantity required",
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
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
                                      print(state.currentProduct!.itemName);
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: SubmitButton(
                                    label: 'Delete',
                                    icon: Icons.delete,
                                    onPressed: () {
                                      print(
                                        "asjkhdkjashdkhas ${state.currentProduct!.itemName}",
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 100.h),
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

        final String? selected =
            (state.selectedUnit != null && units.contains(state.selectedUnit))
            ? state.selectedUnit
            : null;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColor.secondaryColor),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text(
                "Unit Type",
                style: TextStyle(color: AppColor.secondaryColor),
              ),
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
  final String label;
  final IconData? icon;
  final void Function()? onPressed;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          if (icon != null)
            Icon(icon, color: AppColor.secondaryColor, size: 25),
        ],
      ),
    );
  }
}

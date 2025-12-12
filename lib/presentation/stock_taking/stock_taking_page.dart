import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/core/app_images/app_images.dart';
import 'package:apg_scanner/data/model/products_model.dart';
import 'package:apg_scanner/data/model/project_model.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/barcode_scanner_page.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/search_results_page.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/show_item_widget.dart';
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
  Future<bool> _confirmDiscard(BuildContext context) async {
    final unit = context.read<StockBloc>().state.selectedUnit;
    final qtyText = qtyController.text.trim();
    final current = context.read<StockBloc>().state.currentProduct;

    final hasUnsaved = current != null && unit != null && qtyText.isNotEmpty;

    if (!hasUnsaved) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Unsaved Item",
          style: TextStyle(color: AppColor.secondaryColor),
        ),
        content: const Text(
          "You have selected a product and entered quantity.\nDo you want to save it before continuing?",
          style: TextStyle(color: AppColor.secondaryColor),
        ),
        actions: [
          TextButton(
            child: const Text(
              "No",
              style: TextStyle(color: AppColor.secondaryColor),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text(
              "Yes",
              style: TextStyle(color: AppColor.secondaryColor),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) =>
              curr.productAlreadyExists &&
              !prev.productAlreadyExists &&
              curr.currentProduct != null,
          listener: (context, state) async {
            final bloc = context.read<StockBloc>();

            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text("Product already scanned"),
                content: const Text(
                  "This product is already saved.\nDo you want to edit it?",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );

            if (result == true) {
              final existing = state.items.firstWhere(
                (e) => e.itemCode == state.currentProduct!.itemCode,
              );
              qtyController.text = existing.quantity.toString();

              bloc.add(ChangeSelectedIndexEvent(state.items.indexOf(existing)));
              scanController.clear();
            } else {
              bloc.add(ResetFormEvent());
            }

            bloc.add(const ClearProductAlreadyExistsFlagEvent());
          },
        ),
        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) => prev.success != curr.success,
          listener: (context, state) {
            if (state.success == null) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.success!),
                backgroundColor: Colors.green,
              ),
            );

            scanController.clear();
            nameController.clear();
            qtyController.clear();

            context.read<StockBloc>().add(ResetFormEvent());
          },
        ),
        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) => prev.error != curr.error,
          listener: (context, state) {
            if (state.error == null) return;
            print(state.error);
            /*ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );*/
          },
        ),
      ],
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state.success == null && state.currentProduct != null) {
            nameController.text = state.currentProduct!.itemName;
          }
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Confirm Upload"),
                          content: const Text(
                            "Do you want to save and upload all scanned items?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Yes"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        context.read<StockBloc>().add(
                          UploadStockEvent(projectId: projects.name.toString()),
                        );
                      }
                    },
                  ),
                ],
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
                                          final bloc = context
                                              .read<StockBloc>();
                                          final navigator = Navigator.of(
                                            context,
                                          );
                                          final shouldSave =
                                              await _confirmDiscard(context);

                                          if (shouldSave) {
                                            final current =
                                                bloc.state.currentProduct;
                                            final unit =
                                                bloc.state.selectedUnit;
                                            final qty =
                                                int.tryParse(
                                                  qtyController.text,
                                                ) ??
                                                0;

                                            if (current != null &&
                                                unit != null &&
                                                qty > 0) {
                                              bloc.add(
                                                ApproveItemEvent(
                                                  projectId: projects.id
                                                      .toString(),
                                                  barcode: scanController.text,
                                                  unit: unit,
                                                  qty: qty,
                                                ),
                                              );
                                            }
                                          } else {
                                            bloc.add(ResetFormEvent());
                                            scanController.clear();
                                            nameController.clear();
                                            qtyController.clear();
                                          }

                                          final suggestions =
                                              bloc.state.suggestions;

                                          final result = await navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) => SearchResultsPage(
                                                results: suggestions,
                                              ),
                                            ),
                                          );

                                          if (result is ProductModel) {
                                            bloc.add(
                                              ProductChosenFromSearch(result),
                                            );
                                          }
                                        },
                                      ),

                                      IconButton(
                                        icon: const Icon(Icons.scanner),
                                        onPressed: () async {
                                          final bloc = context
                                              .read<StockBloc>();
                                          final navigator = Navigator.of(
                                            context,
                                          );
                                          final shouldSave =
                                              await _confirmDiscard(context);

                                          if (shouldSave) {
                                            final current =
                                                bloc.state.currentProduct;
                                            final unit =
                                                bloc.state.selectedUnit;
                                            final qty =
                                                int.tryParse(
                                                  qtyController.text,
                                                ) ??
                                                0;

                                            if (current != null &&
                                                unit != null &&
                                                qty > 0) {
                                              bloc.add(
                                                ApproveItemEvent(
                                                  projectId: projects.id
                                                      .toString(),
                                                  barcode: scanController.text,
                                                  unit: unit,
                                                  qty: qty,
                                                ),
                                              );
                                            }
                                          } else {
                                            bloc.add(ResetFormEvent());
                                            scanController.clear();
                                            nameController.clear();
                                            qtyController.clear();
                                          }

                                          final barcode = await navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const BarcodeScannerPage(),
                                            ),
                                          );

                                          if (barcode != null) {
                                            scanController.text = barcode;

                                            bloc.add(
                                              ScanBarcodeEvent(
                                                projectId: projects.id
                                                    .toString(),
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
                                        onTap: () async {
                                          final bloc = context
                                              .read<StockBloc>();
                                          final shouldSave =
                                              await _confirmDiscard(context);

                                          if (shouldSave) {
                                            final current =
                                                bloc.state.currentProduct;
                                            final unit =
                                                bloc.state.selectedUnit;
                                            final qty =
                                                int.tryParse(
                                                  qtyController.text,
                                                ) ??
                                                0;

                                            if (current != null &&
                                                unit != null &&
                                                qty > 0) {
                                              bloc.add(
                                                ApproveItemEvent(
                                                  projectId: projects.id
                                                      .toString(),
                                                  barcode: scanController.text,
                                                  unit: unit,
                                                  qty: qty,
                                                ),
                                              );
                                            }
                                          } else {
                                            bloc.add(ResetFormEvent());
                                            scanController.clear();
                                            nameController.clear();
                                            qtyController.clear();
                                          }

                                          bloc.add(ProductChosenFromSearch(p));
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
                                      keyboardType: TextInputType.number,
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

                                        if (unit == null || qty <= 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "Unit & Quantity required",
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: SubmitButton(
                                      label: 'Delete',
                                      icon: Icons.delete,

                                      onPressed: () {
                                        final bloc = context.read<StockBloc>();
                                        final index = bloc.state.selectedIndex;

                                        if (index == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please select an item to delete",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        final item = bloc.state.items[index];

                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              "Delete Item",
                                              style: TextStyle(
                                                color: AppColor.secondaryColor,
                                              ),
                                            ),
                                            content: Text(
                                              "Are you sure you want to delete\n${item.itemName} ?",
                                              style: const TextStyle(
                                                color: AppColor.secondaryColor,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Cancel"),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                              ElevatedButton(
                                                child: const Text("Delete"),
                                                onPressed: () {
                                                  bloc.add(
                                                    DeleteStockEvent(item.id),
                                                  );
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ShowItemsList(
                          onItemSelected: (item) {
                            context.read<StockBloc>().add(
                              ScannedItemSelectedEvent(item),
                            );

                            qtyController.text = item.quantity.toString();
                            FocusScope.of(context).unfocus();
                          },
                          nameController: nameController,
                          qtyController: qtyController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        final baseUnits = state.units;

        final String? selectedUnit = state.selectedUnit;

        final List<String> units = baseUnits.isNotEmpty
            ? baseUnits
            : (selectedUnit != null ? [selectedUnit] : <String>[]);

        final String? selected =
            (selectedUnit != null && units.contains(selectedUnit))
            ? selectedUnit
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: AppColor.secondaryColor,
                ),
              ),
            ),
          ),
          if (icon != null)
            Icon(icon, color: AppColor.secondaryColor, size: 25),
        ],
      ),
    );
  }
}

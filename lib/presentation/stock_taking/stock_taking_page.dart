import 'package:apg_scanner/core/app_color/app_color.dart';
import 'package:apg_scanner/data/model/products_model.dart';
import 'package:apg_scanner/data/model/project_model.dart';
import 'package:apg_scanner/presentation/stock_taking/product_details_block.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_bloc.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_event.dart';
import 'package:apg_scanner/presentation/stock_taking/stock_taking_bloc/stock_taking_state.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/barcode_scanner_page.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/export_botton_sheet.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/search_results_page.dart';
import 'package:apg_scanner/presentation/stock_taking/widgets/show_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../widgets/background_widget.dart';
import '../widgets/top_snackbar.dart';

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

  final FocusNode qtyFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) =>
              curr.productAlreadyExists &&
              !curr.productExistsDialogShown &&
              curr.currentProduct != null,
          listener: (context, state) async {
            final bloc = context.read<StockBloc>();

            bloc.add(MarkProductExistsDialogShownEvent());

            final bool? add = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text("Product already scanned"),
                content: const Text(
                  "This product already exists.\nDo you want to add more quantity?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Add"),
                  ),
                ],
              ),
            );

            // Cancel
            if (add != true) {
              bloc.add(ResetFormEvent());
              scanController.clear();
              nameController.clear();
              qtyController.clear();
              return;
            }

            // Add
            bloc.add(
              SetDuplicateActionEvent(
                DuplicateAction.add,
                forceDefaultBox: true,
              ),
            );
          },
        ),
        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) =>
              prev.currentProduct == null && curr.currentProduct != null,
          listener: (context, state) {
            Future.microtask(() {
              qtyFocusNode.requestFocus();
            });
          },
        ),

        BlocListener<StockBloc, StockState>(
          listenWhen: (prev, curr) => prev.success != curr.success,
          listener: (context, state) {
            if (state.success == null) return;

            showTopSnackBar(
              context,
              message: state.success!,
              backgroundColor: Colors.green,
              icon: Icons.check_circle,
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
            showTopSnackBar(
              context,
              message: state.error!,
              backgroundColor: Colors.red.shade700,
              icon: Icons.error_rounded,
            );
          },
        ),
      ],
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state.success == null && state.currentProduct != null) {
            nameController.text = state.currentProduct!.itemName;
          }
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  "Stock Taking",
                  style: TextStyle(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.secondaryColor,
                  ),
                ),
                centerTitle: true,
                backgroundColor: AppColor.primaryColor,
                actions: [
                  BlocBuilder<StockBloc, StockState>(
                    buildWhen: (prev, curr) =>
                        prev.hasUnsyncedItems != curr.hasUnsyncedItems,
                    builder: (context, state) {
                      return IconButton(
                        icon: Icon(
                          Icons.cloud_upload,
                          color: state.hasUnsyncedItems
                              ? Colors.red.shade700
                              : AppColor.secondaryColor,
                        ),
                        tooltip: state.hasUnsyncedItems
                            ? "Unsynced changes"
                            : "All data uploaded",
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          final bloc = context.read<StockBloc>();

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Confirm Upload"),
                              content: const Text(
                                "Do you want to save and upload all scanned items?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: AppColor.secondaryColor,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
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

                          if (confirm == true) {
                            bloc.add(
                              UploadStockEvent(
                                projectId: projects.id.toString(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  BlocBuilder<StockBloc, StockState>(
                    builder: (context, state) {
                      final disabled = state.hasUnsyncedItems;

                      return IconButton(
                        tooltip: disabled
                            ? "Upload data first"
                            : "Export report",
                        icon: Icon(
                          Icons.download,
                          color: disabled
                              ? Colors.grey.shade700
                              : AppColor.secondaryColor,
                        ),
                        onPressed: disabled
                            ? () {
                                showTopSnackBar(
                                  context,
                                  message:
                                      "Please upload data before exporting",
                                  backgroundColor: Colors.orange,
                                  icon: Icons.cloud_upload,
                                );
                              }
                            : () {
                                FocusManager.instance.primaryFocus?.unfocus();

                                final branchName = getIt<UserSession>().branch;

                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<StockBloc>(),
                                    child: ExportBottomSheet(
                                      projectId: projects.id,
                                      branchName: branchName!,
                                      projectName: projects.name,
                                    ),
                                  ),
                                );
                              },
                      );
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
                                                  projectName: projects.name
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
                                                  projectName: projects.name
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
                                                projectId: projects.id,
                                                barcode: barcode,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  labelStyle: TextStyle(
                                    color: AppColor.secondaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide(
                                      color: AppColor.primaryColor,
                                    ),
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
                                                  projectName: projects.name
                                                      .toString(),
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
                        ProductDetailsBlock(
                          nameController: nameController,
                          qtyController: qtyController,
                          scanController: scanController,

                          projects: projects,
                          qtyFocusNode: qtyFocusNode,
                        ),

                        ShowItemsList(
                          projectId: projects.id.toString(),
                          projectName: projects.name.toString(),
                        ),
                      ],
                    ),
                  ),
                  if (state.isUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              "Uploading data...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (state.isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.processingMessage ?? "Processing...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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

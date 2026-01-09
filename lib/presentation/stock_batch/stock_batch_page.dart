import 'package:apg_scanner/presentation/stock_batch/widgets/batch_search_results_page.dart';
import 'package:apg_scanner/presentation/stock_batch/widgets/stock_batch_export_bottom_sheet.dart';
import 'package:apg_scanner/presentation/stock_batch/widgets/stock_batch_showItems_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_color/app_color.dart';
import '../../data/model/product_with_batch_model.dart';
import '../../data/model/project_model.dart';
import '../stock_taking/widgets/barcode_scanner_page.dart';
import '../widgets/background_widget.dart';
import '../widgets/top_snackbar.dart';
import 'stock_batch_bloc/stock_batch_bloc.dart';
import 'stock_batch_bloc/stock_batch_event.dart';
import 'stock_batch_bloc/stock_batch_state.dart';
import 'widgets/stock_batch_details_block.dart';

class StockBatchPage extends StatelessWidget {
  StockBatchPage({super.key, required this.project});

  final ProjectModel project;

  final scanController = TextEditingController();
  final nameController = TextEditingController();
  final qtyController = TextEditingController();
  final qtyFocusNode = FocusNode();
  final scanFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // SUCCESS
        BlocListener<StockBatchBloc, StockBatchState>(
          listenWhen: (p, c) => p.success != c.success || p.error != c.error,
          listener: (context, state) {
            final message = state.error ?? state.success;
            if (message == null) return;

            final type = state.snackType ?? SnackType.success;

            Color color;
            IconData icon;

            switch (type) {
              case SnackType.info:
                color = Colors.blueGrey;
                icon = Icons.info;
                break;
              case SnackType.error:
                color = Colors.red.shade700;
                icon = Icons.error;
                break;
              case SnackType.success:
                color = Colors.green;
                icon = Icons.check_circle;
            }

            showTopSnackBar(
              context,
              message: message,
              backgroundColor: color,
              icon: icon,
            );

            if (type == SnackType.success) {
              nameController.clear();
              scanController.clear();
              qtyController.clear();
              FocusScope.of(context).requestFocus(scanFocusNode);

              context.read<StockBatchBloc>().add(ResetBatchFormEvent());
            }
          },
        ),

        // SCANNED BARCODE
        BlocListener<StockBatchBloc, StockBatchState>(
          listenWhen: (p, c) => p.scannedBarcode != c.scannedBarcode,
          listener: (context, state) {
            if (state.scannedBarcode != null) {
              scanController.text = state.scannedBarcode!;
            }
          },
        ),
        BlocListener<StockBatchBloc, StockBatchState>(
          listener: (context, state) {
            if (state.currentProduct != null) {
              nameController.text = state.currentProduct!.itemName;
            } else {
              nameController.clear();
            }
          },
        ),
      ],
      child: BlocBuilder<StockBatchBloc, StockBatchState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  "Stock Batch Scan",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.secondaryColor,
                  ),
                ),
                centerTitle: true,
                backgroundColor: AppColor.primaryColor,
                actions: [
                  // ---------------- UPLOAD ----------------
                  BlocBuilder<StockBatchBloc, StockBatchState>(
                    buildWhen: (p, c) =>
                        p.hasUnsyncedItems != c.hasUnsyncedItems,
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
                          final bloc = context.read<StockBatchBloc>();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Confirm Upload"),
                              content: const Text(
                                "Do you want to upload all stock batch items?",
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
                              UploadStockBatchEvent(
                                projectId: project.id.toString(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // ---------------- EXPORT ----------------
                  BlocBuilder<StockBatchBloc, StockBatchState>(
                    builder: (context, state) {
                      final disabled = state.hasUnsyncedItems;

                      return IconButton(
                        tooltip: disabled
                            ? "Upload data first"
                            : "Export Stock Batch report",
                        icon: Icon(
                          Icons.download,
                          color: disabled
                              ? Colors.grey.shade700
                              : AppColor.secondaryColor,
                        ),
                        onPressed: disabled
                            ? () {
                                FocusScope.of(context).unfocus();

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

                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<StockBatchBloc>(),
                                    child: StockBatchExportBottomSheet(
                                      projectId: project.id,
                                      projectName: project.name,
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
                        // ---------------- SCAN / SEARCH ----------------
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            color: const Color(0x1a4eb0de),
                          ),
                          child: TextField(
                            controller: scanController,
                            textInputAction: TextInputAction.done,

                            onChanged: (v) {
                              context.read<StockBatchBloc>().add(
                                SearchBatchQueryChanged(v),
                              );
                            },

                            onSubmitted: (value) async {
                              final bloc = context.read<StockBatchBloc>();
                              final state = bloc.state;
                              if (state.currentProduct != null &&
                                  qtyController.text.isNotEmpty) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                      "Unsaved Item",
                                      style: TextStyle(
                                        color: AppColor.secondaryColor,
                                      ),
                                    ),
                                    content: const Text(
                                      "You have an unapproved item.\nDo you want to save it before continuing?",
                                      style: TextStyle(
                                        color: AppColor.secondaryColor,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text(
                                          "No",
                                          style: TextStyle(
                                            color: AppColor.secondaryColor,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
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
                                  final qty =
                                      double.tryParse(qtyController.text) ?? 0;

                                  if (state.selectedUnit != null && qty > 0) {
                                    bloc.add(
                                      ApproveBatchItemEvent(
                                        projectId: project.id.toString(),
                                        projectName: project.name,
                                        barcode: scanController.text.trim(),
                                        unit: state.selectedUnit!,
                                        qty: qty,
                                      ),
                                    );
                                  }
                                } else {
                                  bloc.add(ResetBatchFormEvent());
                                  scanController.clear();
                                  nameController.clear();
                                  qtyController.clear();
                                }
                              }

                              final suggestions = bloc.state.suggestions;

                              if (suggestions.isEmpty) return;

                              if (suggestions.length == 1) {
                                bloc.add(
                                  ProductChosenFromSearchEvent(
                                    suggestions.first,
                                  ),
                                );
                                return;
                              }

                              final normalized = value.replaceAll(' ', '');

                              final exact = suggestions.where(
                                (p) => p.barcodes.any(
                                  (b) => b.replaceAll(' ', '') == normalized,
                                ),
                              );

                              if (exact.length == 1) {
                                bloc.add(
                                  ProductChosenFromSearchEvent(exact.first),
                                );
                              }
                            },

                            focusNode: scanFocusNode,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: "Scan or Search Product",
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () async {
                                      final bloc = context
                                          .read<StockBatchBloc>();

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BatchSearchResultsPage(
                                                results: bloc.state.suggestions,
                                              ),
                                        ),
                                      );

                                      if (result is ProductWithBatchModel) {
                                        bloc.add(
                                          ProductChosenFromSearchEvent(result),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.scanner),
                                    onPressed: () async {
                                      final bloc = context
                                          .read<StockBatchBloc>();
                                      final state = bloc.state;

                                      final barcode = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const BarcodeScannerPage(),
                                        ),
                                      );

                                      if (barcode == null) return;

                                      if (state.currentProduct != null &&
                                          qtyController.text.isNotEmpty) {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Unsaved Item"),
                                            content: const Text(
                                              "You have selected a product and entered quantity.\nDo you want to save it before continuing?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("No"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text("Yes"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          bloc.add(
                                            ApproveBatchItemEvent(
                                              projectId: project.id.toString(),
                                              projectName: project.name,
                                              barcode: scanController.text
                                                  .trim(),
                                              unit: state.selectedUnit!,
                                              qty:
                                                  double.tryParse(
                                                    qtyController.text,
                                                  ) ??
                                                  0,
                                            ),
                                          );
                                        } else {
                                          bloc.add(ResetBatchFormEvent());
                                        }
                                      }

                                      bloc.add(
                                        ScanBatchBarcodeEvent(
                                          projectId: project.id,
                                          barcode: barcode,
                                        ),
                                      );
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
                        ),
                        if (state.suggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Column(
                              children: state.suggestions.map((p) {
                                return ListTile(
                                  title: Text(p.itemName),
                                  subtitle: Text(p.itemCode),
                                  trailing: p.isBatch
                                      ? const Icon(
                                          Icons.inventory_2,
                                          color: Colors.blue,
                                        )
                                      : null,
                                  onTap: () {
                                    context.read<StockBatchBloc>().add(
                                      ProductChosenFromSearchEvent(p),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                        // ---------------- DETAILS ----------------
                        StockBatchDetailsBlock(
                          project: project,
                          scanController: scanController,
                          nameController: nameController,
                          qtyController: qtyController,
                          qtyFocusNode: qtyFocusNode,
                          scanFocusNode: scanFocusNode,
                        ),
                        StockBatchShowItemsList(
                          projectId: project.id.toString(),
                        ),
                      ],
                    ),
                  ),

                  if (state.isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.45),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
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

import 'package:apg_scanner/presentation/stock_batch/widgets/batch_search_results_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // SUCCESS
        BlocListener<StockBatchBloc, StockBatchState>(
          listenWhen: (p, c) => p.success != c.success,
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

            context.read<StockBatchBloc>().add(ResetBatchFormEvent());
          },
        ),

        // ERROR
        BlocListener<StockBatchBloc, StockBatchState>(
          listenWhen: (p, c) => p.error != c.error,
          listener: (context, state) {
            if (state.error == null) return;

            showTopSnackBar(
              context,
              message: state.error!,
              backgroundColor: Colors.red.shade700,
              icon: Icons.error,
            );
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
      ],
      child: BlocBuilder<StockBatchBloc, StockBatchState>(
        builder: (context, state) {
          if (state.currentProduct != null) {
            nameController.text = state.currentProduct!.itemName;
          }

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
                            onChanged: (v) {
                              context.read<StockBatchBloc>().add(
                                SearchBatchQueryChanged(v),
                              );
                            },
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

                                      if (result != null) {
                                        bloc.add(
                                          ProductChosenFromSearchEvent(result),
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
                                        context.read<StockBatchBloc>().add(
                                          ScanBatchBarcodeEvent(
                                            projectId: project.id,
                                            barcode: barcode,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ---------------- DETAILS ----------------
                        StockBatchDetailsBlock(
                          project: project,
                          scanController: scanController,
                          nameController: nameController,
                          qtyController: qtyController,
                          qtyFocusNode: qtyFocusNode,
                        ),
                      ],
                    ),
                  ),

                  if (state.loading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
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

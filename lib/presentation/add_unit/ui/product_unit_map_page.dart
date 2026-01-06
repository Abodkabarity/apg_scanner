import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/product_unit_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../near_expiry/widgets/barcode_scanner_page.dart';
import '../product_unit_type_bloc.dart';
import '../product_unit_type_event.dart';
import '../product_unit_type_state.dart';

class ProductUnitMapPage extends StatelessWidget {
  const ProductUnitMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductUnitMapBloc(
        getIt<ProductsRepository>(),
        getIt<ProductUnitRepository>(),
      )..add(InitProductUnitMapEvent()),
      child: const _ProductUnitMapView(),
    );
  }
}

class _ProductUnitMapView extends StatefulWidget {
  const _ProductUnitMapView();

  @override
  State<_ProductUnitMapView> createState() => _ProductUnitMapViewState();
}

class _ProductUnitMapViewState extends State<_ProductUnitMapView> {
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan(BuildContext context) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (!context.mounted) return;
    if (barcode == null || barcode.isEmpty) return;

    final bloc = context.read<ProductUnitMapBloc>();
    final productsRepo = getIt<ProductsRepository>();

    final p = productsRepo.findByBarcode(barcode);

    if (p == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Barcode not found: $barcode")));
      return;
    }

    bloc.add(SelectProductEvent(product: p, barcode: barcode));
    searchCtrl.text = barcode;
    bloc.add(SearchQueryChangedEvent(barcode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Product Units",
          style: TextStyle(
            color: AppColor.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primaryColor,
        centerTitle: true,
      ),
      body: BlocConsumer<ProductUnitMapBloc, ProductUnitMapState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final p = state.selectedProduct;

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search + Scan
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (v) => context
                            .read<ProductUnitMapBloc>()
                            .add(SearchQueryChangedEvent(v)),
                        decoration: InputDecoration(
                          hintText: "Search by name / code / barcode",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SizedBox(
                      height: 52.h,
                      width: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _scan(context),
                        child: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                if (state.searchResults.isNotEmpty)
                  Container(
                    height: 170.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: state.searchResults.length,
                      itemBuilder: (_, i) {
                        final r = state.searchResults[i];
                        return ListTile(
                          title: Text(
                            r.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text("Code: ${r.itemCode}"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final bc = r.barcodes.isNotEmpty
                                ? r.barcodes.first
                                : "";
                            context.read<ProductUnitMapBloc>().add(
                              SelectProductEvent(product: r, barcode: bc),
                            );
                          },
                        );
                      },
                    ),
                  ),

                SizedBox(height: 12.h),

                // Selected product card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Product",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(p?.itemName ?? "-"),
                      Text("Code: ${p?.itemCode ?? "-"}"),
                      Text("Barcode: ${state.selectedBarcode ?? "-"}"),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Unit dropdown + Add
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state.selectedUnit,
                        items: state.allUnits
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          context.read<ProductUnitMapBloc>().add(
                            UnitSelectedEvent(v),
                          );
                        },
                        decoration: InputDecoration(
                          labelText: "Select Unit",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => context.read<ProductUnitMapBloc>().add(
                          AddMappingEvent(),
                        ),
                        child: const Text("Add"),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Sync button + pending count
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: state.syncing
                            ? null
                            : () => context.read<ProductUnitMapBloc>().add(
                                SyncPendingEvent(),
                              ),
                        icon: state.syncing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          "Sync to Supabase (${state.pending.length})",
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Text(
                  "Added Items",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),

                Expanded(
                  child: state.pending.isEmpty
                      ? const Center(child: Text("No items added yet"))
                      : ListView.builder(
                          itemCount: state.pending.length,
                          itemBuilder: (_, i) {
                            final x = state.pending[i];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  x.itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  "Code: ${x.itemCode} | Barcode: ${x.barcode} | Unit: ${x.unit}",
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => context
                                      .read<ProductUnitMapBloc>()
                                      .add(RemoveMappingEvent(x.key)),
                                ),
                              ),
                            );
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
}

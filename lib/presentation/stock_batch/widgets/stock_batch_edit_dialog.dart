import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_batch_group.dart';

class StockBatchMultiUnitDialog extends StatefulWidget {
  final StockBatchGroup group;

  /// BOX / STRIP / ...
  final Map<String, double> initialUnitQty;

  final DateTime? initialExpiry;
  final String? initialBatch;

  final void Function(
    Map<String, double> unitQty,
    DateTime? expiry,
    String? batch,
  )
  onApply;

  final VoidCallback onDelete;
  final List<String> allUnits;
  final int subUnitQty;

  const StockBatchMultiUnitDialog({
    super.key,
    required this.group,
    required this.initialUnitQty,
    required this.initialExpiry,
    required this.initialBatch,
    required this.onApply,
    required this.onDelete,
    required this.allUnits,
    required this.subUnitQty,
  });

  @override
  State<StockBatchMultiUnitDialog> createState() =>
      _StockBatchMultiUnitDialogState();
}

class _StockBatchMultiUnitDialogState extends State<StockBatchMultiUnitDialog> {
  late Map<String, TextEditingController> _controllers;
  DateTime? _selectedExpiry;
  String? _batch;

  @override
  void initState() {
    super.initState();

    _selectedExpiry = widget.initialExpiry;
    _batch = widget.initialBatch;

    _controllers = {
      for (final unit in widget.allUnits)
        unit: TextEditingController(
          text: (widget.initialUnitQty[unit] ?? 0).toString(),
        ),
    };
  }

  double get _totalQty {
    double total = 0;

    for (final entry in _controllers.entries) {
      final unit = entry.key.toLowerCase();
      final qty = double.tryParse(entry.value.text) ?? 0;

      if (unit == 'box') {
        total += qty;
      } else {
        if (widget.subUnitQty > 0) {
          total += qty / widget.subUnitQty;
        }
      }
    }

    return total;
  }

  String _formatMonth(DateTime d) =>
      "${d.month.toString().padLeft(2, '0')}/${d.year}";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
      title: Text(
        widget.group.itemName,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.secondaryColor,
        ),
      ),

      // ------------------------------------------------------------
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ---------------- UNITS ----------------
            ..._controllers.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColor.secondaryColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90.w,
                      child: TextField(
                        controller: e.value,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 20),

            /// ---------------- TOTAL ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Quantity",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.secondaryColor,
                  ),
                ),
                Text(
                  _totalQty.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.secondaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// ---------------- NEAR EXPIRY ----------------
            if (_selectedExpiry != null)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: _selectedExpiry!,
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedExpiry = DateTime(picked.year, picked.month, 1);
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Near Expiry: ${_formatMonth(_selectedExpiry!)}",
                        style: const TextStyle(color: AppColor.secondaryColor),
                      ),
                    ],
                  ),
                ),
              ),

            /// ---------------- BATCH ----------------
            if (_batch != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _batch),
                decoration: const InputDecoration(
                  labelText: "Batch",
                  isDense: true,
                ),
                onChanged: (v) => _batch = v,
              ),
            ],
          ],
        ),
      ),

      // ------------------------------------------------------------
      actions: [
        /// DELETE
        TextButton(
          onPressed: () {
            widget.onDelete();
            Navigator.pop(context);
          },
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),

        /// CANCEL
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        /// APPLY
        ElevatedButton(
          onPressed: () {
            final result = <String, double>{};

            for (final e in _controllers.entries) {
              final qty = double.tryParse(e.value.text) ?? 0;
              if (qty > 0) {
                result[e.key] = qty;
              }
            }

            widget.onApply(result, _selectedExpiry, _batch);
            Navigator.pop(context);
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}

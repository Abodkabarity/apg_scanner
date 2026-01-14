import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/utils/text_input_formatter.dart';
import '../../../data/model/stock_batch_group.dart';

class StockBatchMultiUnitDialog extends StatefulWidget {
  final StockBatchGroup group;

  final bool isBatch;

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
    required this.isBatch,
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

  late final TextEditingController _batchController;

  @override
  void initState() {
    super.initState();

    _selectedExpiry = widget.initialExpiry == null
        ? null
        : DateTime(widget.initialExpiry!.year, widget.initialExpiry!.month, 1);

    _batch = widget.initialBatch;

    _batchController = TextEditingController(text: _batch ?? '');

    _controllers = {
      for (final unit in widget.allUnits)
        unit: TextEditingController(
          text: (widget.initialUnitQty[unit] ?? 0).toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _batchController.dispose();
    super.dispose();
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

  Future<DateTime?> showMonthYearPicker(BuildContext context) async {
    int selectedMonth = (_selectedExpiry ?? DateTime.now()).month;
    int selectedYear = (_selectedExpiry ?? DateTime.now()).year;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Expiry (MM / YYYY)'),
          content: Row(
            children: [
              // MONTH
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedMonth,
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text((i + 1).toString().padLeft(2, '0')),
                    ),
                  ),
                  onChanged: (v) => selectedMonth = v!,
                  decoration: const InputDecoration(labelText: 'Month'),
                ),
              ),
              const SizedBox(width: 12),
              // YEAR
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedYear,
                  items: List.generate(15, (i) {
                    final year = DateTime.now().year + i;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (v) => selectedYear = v!,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  DateTime(selectedYear, selectedMonth, 1),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
                          FilteringTextInputFormatter.digitsOnly,
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

            /// ✅ ---------------- NEAR EXPIRY (ONLY Month/Year Picker) ----------------
            if (widget.isBatch) ...[
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showMonthYearPicker(context);
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
                        _selectedExpiry == null
                            ? "Select Near Expiry (MM/YYYY)"
                            : "Near Expiry: ${_formatMonth(_selectedExpiry!)}",
                        style: const TextStyle(color: AppColor.secondaryColor),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// ✅ ---------------- BATCH (always visible if isBatch) ----------------
              TextField(
                controller: _batchController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  labelText: "Batch",
                  isDense: true,
                ),
                onChanged: (v) {
                  _batch = v.trim().toUpperCase();
                },
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
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  "Delete Item",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Are you sure you want to delete?",
                      textAlign: TextAlign.start,
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                    Text(
                      widget.group.itemName,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColor.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text(
                      "No",
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    child: const Text(
                      "Yes",
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                    onPressed: () {
                      widget.onDelete();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
          child: const Text("Delete Item", style: TextStyle(color: Colors.red)),
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

            if (widget.isBatch) {
              final batchText = (_batchController.text).trim();
              _batch = batchText.isEmpty ? null : batchText.toUpperCase();

              if (_selectedExpiry == null) {
                return;
              }
              if (_batch == null || _batch!.isEmpty) {
                return;
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_item_group.dart';

class NearExpiryMultiUnitDialog extends StatefulWidget {
  final StockItemGroup group;
  final List<String> allUnits;
  final int numberSubUnit;

  /// 🔹 initial value from group
  final DateTime initialNearExpiry;

  /// 🔹 qty + near expiry
  final void Function(Map<String, int>, DateTime) onApply;

  final VoidCallback onDelete;

  const NearExpiryMultiUnitDialog({
    super.key,
    required this.group,
    required this.allUnits,
    required this.numberSubUnit,
    required this.initialNearExpiry,
    required this.onApply,
    required this.onDelete,
  });

  @override
  State<NearExpiryMultiUnitDialog> createState() =>
      _NearExpiryMultiUnitDialogState();
}

class _NearExpiryMultiUnitDialogState extends State<NearExpiryMultiUnitDialog> {
  late Map<String, TextEditingController> controllers;
  double total = 0;

  late List<DateTime> expiryOptions;
  DateTime? selectedNearExpiry;

  @override
  void initState() {
    super.initState();

    expiryOptions = _generateNearExpiryMonths();

    // normalize to month only
    selectedNearExpiry = DateTime(
      widget.initialNearExpiry.year,
      widget.initialNearExpiry.month,
      1,
    );

    controllers = {
      for (final unit in widget.allUnits)
        unit: TextEditingController(
          text: widget.group.unitQty[unit]?.toString() ?? "0",
        ),
    };

    _recalculateTotal();
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------
  List<DateTime> _generateNearExpiryMonths() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month + 2, 1);

    return List.generate(8, (i) => DateTime(start.year, start.month + i, 1));
  }

  String _formatMonth(DateTime d) =>
      "${d.month.toString().padLeft(2, '0')}/${d.year}";

  // ------------------------------------------------------
  void _recalculateTotal() {
    double sum = 0;

    controllers.forEach((unit, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;

      if (unit.toLowerCase() == "box") {
        sum += qty.toDouble();
      } else {
        if (widget.numberSubUnit > 0) {
          sum += qty / widget.numberSubUnit;
        } else {
          sum += qty.toDouble();
        }
      }
    });

    setState(() => total = sum);
  }

  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.group.itemName,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.secondaryColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ---------------- Near Expiry (DROPDOWN) ----------------
            DropdownButtonFormField<DateTime>(
              initialValue:
                  expiryOptions.any(
                    (d) =>
                        selectedNearExpiry != null &&
                        d.year == selectedNearExpiry!.year &&
                        d.month == selectedNearExpiry!.month,
                  )
                  ? selectedNearExpiry
                  : null,
              items: expiryOptions
                  .map(
                    (d) => DropdownMenuItem<DateTime>(
                      value: d,
                      child: Text(
                        _formatMonth(d),
                        style: TextStyle(color: AppColor.secondaryColor),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => selectedNearExpiry = v);
              },

              decoration: InputDecoration(
                labelText: "Near Expiry Date",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// ---------------- Units ----------------
            ...controllers.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(color: AppColor.secondaryColor),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: entry.value,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _recalculateTotal(),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.r),
                            borderSide: BorderSide(
                              color: AppColor.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            /// ---------------- Total ----------------
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
                  total.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: AppColor.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        /// ---------------- Delete ----------------
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(
                  "Delete Item",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Are you sure you want to delete?",
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.group.itemName,
                      style: TextStyle(
                        color: AppColor.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "No",
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onDelete();
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Yes",
                      style: TextStyle(color: AppColor.secondaryColor),
                    ),
                  ),
                ],
              ),
            );
          },
          child: const Text("Delete Item", style: TextStyle(color: Colors.red)),
        ),

        /// ---------------- Cancel ----------------
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: AppColor.secondaryColor, fontSize: 14.sp),
          ),
        ),

        /// ---------------- Apply ----------------
        ElevatedButton(
          onPressed: selectedNearExpiry == null
              ? null
              : () {
                  final result = <String, int>{};

                  controllers.forEach((unit, ctrl) {
                    result[unit] = int.tryParse(ctrl.text) ?? 0;
                  });

                  widget.onApply(result, selectedNearExpiry!);

                  Navigator.pop(context);
                },
          child: Text(
            "Apply",
            style: TextStyle(color: AppColor.secondaryColor, fontSize: 15.sp),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_item_group.dart';

class MultiUnitEditDialog extends StatefulWidget {
  final StockItemGroup group;
  final List<String> allUnits;
  final int numberSubUnit;
  final void Function(Map<String, int>) onApply;

  const MultiUnitEditDialog({
    super.key,
    required this.group,
    required this.allUnits,
    required this.numberSubUnit,
    required this.onApply,
  });

  @override
  State<MultiUnitEditDialog> createState() => _MultiUnitEditDialogState();
}

class _MultiUnitEditDialogState extends State<MultiUnitEditDialog> {
  late Map<String, TextEditingController> controllers;
  double total = 0;

  @override
  void initState() {
    super.initState();

    controllers = {
      for (final unit in widget.allUnits)
        unit: TextEditingController(
          text: widget.group.unitQty[unit]?.toString() ?? "0",
        ),
    };

    _recalc();
  }

  void _recalc() {
    double sum = 0;

    controllers.forEach((unit, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;

      if (unit.toLowerCase() == "box") {
        sum += qty;
      } else {
        if (widget.numberSubUnit > 0) {
          sum += qty / widget.numberSubUnit;
        } else {
          sum += qty;
        }
      }
    });

    setState(() => total = sum);
  }

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...controllers.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: e.value,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalc(),
                      decoration: InputDecoration(
                        isDense: true,
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(color: AppColor.primaryColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(color: AppColor.primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
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
      actions: [
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
                      widget.onApply(const {});
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: AppColor.secondaryColor, fontSize: 14.sp),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final result = <String, int>{};

            controllers.forEach((unit, ctrl) {
              result[unit] = int.tryParse(ctrl.text) ?? 0;
            });

            widget.onApply(result);
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

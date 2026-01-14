import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/app_color/app_color.dart';
import '../../../data/model/stock_item_group.dart';
import '../near_expiry_bloc/near_expiry_bloc.dart';
import '../near_expiry_bloc/near_expiry_event.dart';
import '../near_expiry_bloc/near_expiry_state.dart';

class NearExpiryMultiUnitDialog extends StatefulWidget {
  final StockItemGroup group;
  final List<String> allUnits;
  final int numberSubUnit;

  final VoidCallback onDelete;
  final void Function(Map<String, int>, DateTime) onApply;

  const NearExpiryMultiUnitDialog({
    super.key,
    required this.group,
    required this.allUnits,
    required this.numberSubUnit,
    required this.onApply,
    required this.onDelete,
  });

  @override
  State<NearExpiryMultiUnitDialog> createState() =>
      _NearExpiryMultiUnitDialogState();
}

class _NearExpiryMultiUnitDialogState extends State<NearExpiryMultiUnitDialog> {
  late final Map<String, TextEditingController> _controllers;

  // ------------------------------------------------------
  String _formatMonth(DateTime d) =>
      "${d.month.toString().padLeft(2, '0')}/${d.year}";

  double _calculateTotal(Map<String, int> unitQty, int numberSubUnit) {
    double sum = 0;

    for (final entry in unitQty.entries) {
      final unit = entry.key;
      final qty = entry.value;

      if (unit.toLowerCase() == 'box') {
        sum += qty.toDouble();
      } else {
        if (numberSubUnit > 0) {
          sum += qty / numberSubUnit;
        } else {
          sum += qty.toDouble();
        }
      }
    }

    return sum;
  }

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final unit in widget.allUnits)
        unit: TextEditingController(
          text: (widget.group.unitQty[unit] ?? 0).toString(),
        ),
    };
  }

  @override
  void didUpdateWidget(covariant NearExpiryMultiUnitDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group.itemCode != widget.group.itemCode ||
        oldWidget.group.nearExpiry != widget.group.nearExpiry) {
      for (final unit in widget.allUnits) {
        _controllers[unit]?.text = (widget.group.unitQty[unit] ?? 0).toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, int> _readQtyFromControllers() {
    return {
      for (final unit in widget.allUnits)
        unit: int.tryParse(_controllers[unit]?.text.trim() ?? '') ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NearExpiryBloc>();

    return AlertDialog(
      title: Text(
        widget.group.itemName,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: AppColor.secondaryColor,
        ),
      ),

      // ======================================================
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<NearExpiryBloc, NearExpiryState>(
              buildWhen: (p, c) => p.editingNearExpiry != c.editingNearExpiry,
              builder: (context, state) {
                final selectedExpiry =
                    state.editingNearExpiry ?? widget.group.nearExpiry!;

                return DropdownButtonFormField<DateTime>(
                  initialValue: DateTime(
                    selectedExpiry.year,
                    selectedExpiry.month,
                    1,
                  ),
                  items: state.nearExpiryOptions
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
                    if (v == null) return;
                    bloc.add(UpdateEditingNearExpiryEvent(v));
                  },
                  decoration: InputDecoration(
                    labelText: "Near Expiry Date",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            ...widget.allUnits.map((unit) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        unit,
                        style: TextStyle(color: AppColor.secondaryColor),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: _controllers[unit],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) {
                          final qty = int.tryParse(v) ?? 0;
                          bloc.add(UpdateEditingUnitQtyEvent(unit, qty));
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
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
              );
            }),

            const Divider(),

            BlocBuilder<NearExpiryBloc, NearExpiryState>(
              buildWhen: (p, c) => p.editingUnitQty != c.editingUnitQty,
              builder: (context, state) {
                final qtyMap = _readQtyFromControllers();
                final total = _calculateTotal(qtyMap, widget.numberSubUnit);

                return Row(
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
                );
              },
            ),
          ],
        ),
      ),

      // ======================================================
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
                      widget.onDelete();
                      bloc.add(const ResetFormEvent());
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

        /// Cancel
        TextButton(
          onPressed: () {
            bloc.add(const ResetFormEvent());
            Navigator.pop(context);
          },
          child: Text(
            "Cancel",
            style: TextStyle(color: AppColor.secondaryColor),
          ),
        ),

        /// Apply
        ElevatedButton(
          onPressed: () {
            final qtyMap = _readQtyFromControllers();

            final st = context.read<NearExpiryBloc>().state;
            final selectedExpiry =
                st.editingNearExpiry ?? widget.group.nearExpiry!;

            widget.onApply(qtyMap, selectedExpiry);
            bloc.add(const ResetFormEvent());
            Navigator.pop(context);
          },
          child: Text(
            "Apply",
            style: TextStyle(color: AppColor.secondaryColor),
          ),
        ),
      ],
    );
  }
}

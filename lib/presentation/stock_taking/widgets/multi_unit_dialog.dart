import 'package:flutter/material.dart';

import '../../../data/model/stock_item_group.dart';

class MultiUnitEditDialog extends StatefulWidget {
  final StockItemGroup group;
  final num numberSubUnit;
  final void Function(Map<String, int> newUnitQty) onApply;

  const MultiUnitEditDialog({
    super.key,
    required this.group,
    required this.numberSubUnit,
    required this.onApply,
  });

  @override
  State<MultiUnitEditDialog> createState() => _MultiUnitEditDialogState();
}

class _MultiUnitEditDialogState extends State<MultiUnitEditDialog> {
  late Map<String, TextEditingController> controllers;

  double totalSubQty = 0;

  @override
  void initState() {
    super.initState();

    controllers = {
      for (final e in widget.group.unitQty.entries)
        e.key: TextEditingController(text: e.value.toString()),
    };

    _recalc();
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalc() {
    double sum = 0;

    controllers.forEach((unit, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;

      if (unit.toLowerCase() == 'box') {
        sum += qty.toDouble();
      } else {
        if (widget.numberSubUnit > 0) {
          sum += qty / widget.numberSubUnit;
        } else {
          sum += qty.toDouble();
        }
      }
    });

    setState(() => totalSubQty = sum);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group.itemName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...controllers.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: e.value,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalc(), // ✅ تحديث مباشر
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
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
                "Total",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                totalSubQty.toStringAsFixed(2), // ✅ الصحيح
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
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
          child: const Text("Apply"),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../data/model/product_with_batch_model.dart';

class BatchSearchResultsPage extends StatelessWidget {
  const BatchSearchResultsPage({super.key, required this.results});

  final List<ProductWithBatchModel> results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Product")),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (_, i) {
          final p = results[i];
          return ListTile(
            title: Text(p.itemName),
            subtitle: Text(p.itemCode),
            trailing: p.isBatch
                ? const Icon(Icons.inventory_2, color: Colors.blue)
                : null,
            onTap: () {
              Navigator.pop(context, p);
            },
          );
        },
      ),
    );
  }
}

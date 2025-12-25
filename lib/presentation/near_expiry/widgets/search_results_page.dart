import 'package:flutter/material.dart';

import '../../../data/model/products_model.dart';

class SearchResultsPage extends StatelessWidget {
  final List<ProductModel> results;

  const SearchResultsPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Results")),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (_, i) {
          final p = results[i];
          return ListTile(
            title: Text(p.itemName),
            subtitle: Text(p.itemCode),
            onTap: () => Navigator.pop(context, p),
          );
        },
      ),
    );
  }
}

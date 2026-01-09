import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/products_model.dart';

class ProductsRemoteService {
  final SupabaseClient client;

  ProductsRemoteService(this.client);

  /// Fetch all (no pagination)
  Future<List<ProductModel>> fetchAllProducts() async {
    final data = await client.from('products').select();

    return (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all products with pagination (SAFE)
  Future<List<ProductModel>> fetchAllPaged({
    int pageSize = 5000,
    void Function(int fetched)? onProgress,
  }) async {
    final List<ProductModel> all = [];
    int from = 0;

    while (true) {
      final to = from + pageSize - 1;

      final rows = await client
          .from('products')
          .select()
          .order('id', ascending: true)
          .range(from, to);

      final list = (rows as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      all.addAll(list);
      onProgress?.call(all.length);

      if (list.length < pageSize) break;

      from += pageSize;
    }

    return all;
  }

  /// Fetch a range for pagination
  Future<List<ProductModel>> fetchRange(int from, int to) async {
    final data = await client
        .from('products')
        .select()
        .order('id', ascending: true)
        .range(from, to);

    return (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

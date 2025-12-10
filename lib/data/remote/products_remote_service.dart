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

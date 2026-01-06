import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/product_with_batch_model.dart';

class ProductsWithBatchRemoteService {
  final SupabaseClient _db;
  ProductsWithBatchRemoteService(this._db);

  /// Full download paginated (لأول مرة فقط)
  Future<List<ProductWithBatchModel>> fetchAllPaged({
    int pageSize = 5000,
    void Function(int fetched)? onProgress,
  }) async {
    final List<ProductWithBatchModel> all = [];
    int from = 0;

    while (true) {
      final to = from + pageSize - 1;

      final rows = await _db
          .from('products_with_batch')
          .select(
            'item_code,item_name,barcodes,units,subunit_qty,is_batch,near_expiry_date,batches',
          )
          .order('item_code', ascending: true)
          .range(from, to);

      final list = (rows as List)
          .map((e) => ProductWithBatchModel.fromMap(e as Map<String, dynamic>))
          .toList();

      all.addAll(list);
      onProgress?.call(all.length);

      if (list.length < pageSize) break;
      from += pageSize;
    }

    return all;
  }

  Future<List<ProductWithBatchModel>> fetchChangedSince({
    required String sinceIso,
    int pageSize = 1000,
    void Function(int fetched)? onProgress,
  }) async {
    final List<ProductWithBatchModel> all = [];

    String? lastUpdatedAt = sinceIso;

    while (true) {
      final rows = await _db
          .from('products_with_batch')
          .select(
            'id,item_code,item_name,barcodes,units,subunit_qty,is_batch,near_expiry_date,batches,updated_at',
          )
          .gt('updated_at', lastUpdatedAt!)
          .order('updated_at', ascending: true)
          .limit(pageSize);

      final list = (rows as List)
          .map((e) => ProductWithBatchModel.fromMap(e))
          .toList();

      if (list.isEmpty) break;

      all.addAll(list);
      onProgress?.call(all.length);

      lastUpdatedAt = (rows.last as Map)['updated_at'].toString();

      if (list.length < pageSize) break;
    }

    return all;
  }
}

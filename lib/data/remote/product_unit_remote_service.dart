import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/product_unit_map_model.dart';

class ProductUnitRemoteService {
  final SupabaseClient client;
  ProductUnitRemoteService(this.client);

  Future<List<String>> fetchAllUnitsDistinct() async {
    final res = await client.from('products').select('subunit');

    final set = <String>{};

    for (final row in (res as List)) {
      final v = (row['subunit'] ?? '').toString().trim();
      if (v.isNotEmpty) set.add(_normalizeUnit(v));
    }

    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<List<ProductUnitMapModel>> upsertMappings({
    required List<ProductUnitMapModel> items,
    required String? createdBy,
  }) async {
    if (items.isEmpty) return [];

    final payload = items.map((e) => e.toJson(createdBy: createdBy)).toList();

    final res = await client
        .from('product_units')
        .upsert(payload, onConflict: 'item_code,barcode,unit_type')
        .select();

    return (res as List)
        .map((e) => ProductUnitMapModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _normalizeUnit(String u) {
    u = u.trim();
    if (u.isEmpty) return "";
    return u[0].toUpperCase() + u.substring(1).toLowerCase();
  }
}

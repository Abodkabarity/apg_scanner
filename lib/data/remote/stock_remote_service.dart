import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/stock_taking_model.dart';

class StockRemoteService {
  final SupabaseClient client;

  StockRemoteService(this.client);

  Future<void> syncUp(List<StockItemModel> items) async {
    if (items.isEmpty) return;

    final body = items.map((e) => e.toJson()).toList();
    await client.from('stock_taking_items').upsert(body);
  }

  Future<List<StockItemModel>> fetchForProject(int projectId) async {
    final response = await client
        .from('stock_taking_items')
        .select()
        .eq('project_name', projectId)
        .eq('is_deleted', false);

    return (response as List).map((e) => StockItemModel.fromJson(e)).toList();
  }
}

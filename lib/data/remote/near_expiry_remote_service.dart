import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/near_expiry_item_model.dart';

class NearExpiryRemoteService {
  final SupabaseClient client;

  NearExpiryRemoteService(this.client);

  Future<void> syncUp(List<NearExpiryItemModel> items) async {
    if (items.isEmpty) return;

    final body = items.map((e) => e.toJson()).toList();

    await client.from('near_expiry_items').upsert(body);
  }

  Future<List<NearExpiryItemModel>> fetchForProject(String projectId) async {
    final response = await client
        .from('near_expiry_items')
        .select()
        .eq('project_id', projectId)
        .eq('is_deleted', false);

    return (response as List)
        .map((e) => NearExpiryItemModel.fromJson(e))
        .toList();
  }
}

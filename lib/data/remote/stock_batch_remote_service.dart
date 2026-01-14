import 'package:supabase_flutter/supabase_flutter.dart';

class StockBatchRemoteService {
  final SupabaseClient client;

  StockBatchRemoteService(this.client);

  Future<void> replaceProjectSnapshot({
    required String projectId,
    required String branchName,
    required List<Map<String, dynamic>> payload,
  }) async {
    await client.from('stock_taking_batch_items').delete().match({
      'project_id': projectId,
      'branch_name': branchName,
    });

    if (payload.isNotEmpty) {
      await client.from('stock_taking_batch_items').insert(payload);
    }
  }
}

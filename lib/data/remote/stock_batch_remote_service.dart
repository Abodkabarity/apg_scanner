import 'package:supabase_flutter/supabase_flutter.dart';

class StockBatchRemoteService {
  final SupabaseClient client;
  StockBatchRemoteService(this.client);

  Future<void> uploadBatchItems(List<Map<String, dynamic>> payload) async {
    if (payload.isEmpty) return;

    // insert bulk
    await client.from('stock_taking_batch_items').insert(payload);
  }
}

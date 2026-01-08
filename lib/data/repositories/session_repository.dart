import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> startNameSession(String name, String deviceId) {
    return _client
        .from('stock_name_sessions')
        .insert({'name': name, 'device_id': deviceId})
        .select()
        .single();
  }
}

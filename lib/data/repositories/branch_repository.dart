import 'package:supabase_flutter/supabase_flutter.dart';

class BranchRepository {
  final SupabaseClient supabase;

  BranchRepository(this.supabase);

  Future<String?> getEmailByBranchName(String branchName) async {
    final res = await supabase
        .from('branches')
        .select('email')
        .eq('branch_name', branchName)
        .maybeSingle();
    print(res?['email']);
    return res?['email'];
  }
}

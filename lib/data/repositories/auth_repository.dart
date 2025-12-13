import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/injection.dart';
import '../../core/session/user_session.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  Future<AuthResponse> login(String email, String password) {
    return authService.login(email, password);
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    getIt<UserSession>().clear();
  }

  User? getCurrentUser() {
    return authService.currentUser;
  }
}

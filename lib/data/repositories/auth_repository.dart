import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  Future<AuthResponse> login(String email, String password) {
    return authService.login(email, password);
  }

  Future<void> logout() {
    return authService.logout();
  }

  User? getCurrentUser() {
    return authService.currentUser;
  }
}

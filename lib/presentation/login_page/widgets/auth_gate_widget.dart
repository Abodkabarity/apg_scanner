import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/session/user_session.dart';
import '../../add_project/add_project_page.dart';
import '../login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _restoreSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    getIt<UserSession>().setUser(
      email: profile['email'],
      branch: profile['branch_name'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _restoreSession(),
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session != null) {
          return AddProjectPage();
        }

        return LoginPage();
      },
    );
  }
}

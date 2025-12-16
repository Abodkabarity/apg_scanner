import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/di/injection.dart';
import '../../../core/session/user_session.dart';
import '../../add_project/add_project_page.dart';
import '../../add_project/project_bloc/project_bloc.dart';
import '../../add_project/project_bloc/project_event.dart';
import '../login_block/login_bloc.dart';
import '../login_block/login_event.dart';
import '../login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _restoreFuture;

  Future<void> _restoreSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    getIt<UserSession>().setUser(
      userId: user.id,
      email: profile['email'],
      branch: profile['branch_name'],
    );
  }

  @override
  void initState() {
    super.initState();
    _restoreFuture = _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor),
            ),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          context.read<ProjectBloc>().add(LoadProjectsEvent());

          return AddProjectPage(key: ValueKey(getIt<UserSession>().userId));
        }

        return BlocProvider.value(
          value: context.read<LoginBloc>()..add(LoginPageOpened()),
          child: LoginPage(),
        );
      },
    );
  }
}

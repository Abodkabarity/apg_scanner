import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_color/app_color.dart';
import '../../../core/di/injection.dart';
import '../../../core/session/user_session.dart';
import '../../../data/services/connectivity_service.dart';
import '../../select_project/select_project_page.dart';
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

  bool _hasInternet = true;
  bool _checkingInternet = true;

  /// 🔹 Restore session from Supabase
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

  /// 🔹 Check internet connection
  Future<void> _checkInternet() async {
    final hasNet = await getIt<ConnectivityService>().hasInternet();

    setState(() {
      _hasInternet = hasNet;
      _checkingInternet = false;
    });

    if (!hasNet) {
      _showNoInternetDialog();
    }
  }

  /// 🔹 Show No Internet dialog
  void _showNoInternetDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("No Internet Connection"),
          content: const Text(
            "Please check your internet connection and try again.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              },

              child: const Text("Retry"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _restoreFuture = _restoreSession();
    _checkInternet();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _restoreFuture,
      builder: (context, snapshot) {
        /// ⏳ Checking internet
        if (_checkingInternet) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor),
            ),
          );
        }

        /// ❌ No internet (dialog already shown)
        if (!_hasInternet) {
          return const Scaffold(body: SizedBox.shrink());
        }

        /// ⏳ Restoring session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor),
            ),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;

        /// ✅ Logged in
        if (session != null) {
          return SelectProjectPage(key: ValueKey(getIt<UserSession>().userId));
        }

        /// 🔐 Not logged in
        return BlocProvider.value(
          value: context.read<LoginBloc>()..add(LoginPageOpened()),
          child: LoginPage(),
        );
      },
    );
  }
}

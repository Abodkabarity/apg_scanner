import 'package:apg_scanner/presentation/add_project/project_bloc/project_bloc.dart';
import 'package:apg_scanner/presentation/login_page/login_block/login_bloc.dart';
import 'package:apg_scanner/presentation/login_page/widgets/auth_gate_widget.dart';
import 'package:apg_scanner/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection.dart';
import 'data/model/near_expiry_item_model.dart';
import 'data/model/stock_taking_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(StockItemModelAdapter());
  Hive.registerAdapter(NearExpiryItemModelAdapter());

  // Load .env (Mobile/Desktop only)
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  // Supabase (Web uses --dart-define, others use .env)
  final supabaseUrl = kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';

  final supabaseAnonKey = kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Supabase URL/AnonKey missing. '
      'Web: pass --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=... '
      'Mobile/Desktop: ensure .env contains SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Dependency Injection
  setupGetIt();

  runApp(const APGScanner());
}

class APGScanner extends StatelessWidget {
  const APGScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (_) => getIt<LoginBloc>()),
        BlocProvider<ProjectBloc>(create: (_) => getIt<ProjectBloc>()),
      ],
      child: ScreenUtilInit(
        designSize: kIsWeb ? const Size(1440, 900) : const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: kIsWeb ? AuthGate() : SplashScreen(),
          );
        },
      ),
    );
  }
}

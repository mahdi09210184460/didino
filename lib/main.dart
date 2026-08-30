import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/referral_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // مقداردهی سوپابیس با اطلاعات واقعی پروژه شما
  await Supabase.initialize(
    url: 'https://jhjhvwvpebexhlfnmveh.supabase.co',
    publishableKey: 'sb_publishable_JDRwWMcVCSviyQd_3Bfo-w_eeNrynQK',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const DidinoApp(),
    ),
  );
}

class DidinoApp extends StatelessWidget {
  const DidinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('fa', 'IR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.isAuthenticated ? const HomeScreen() : const AuthScreen();
        },
      ),
    );
  }
}

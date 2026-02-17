import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(
          create: (BuildContext context) =>
              FirestoreService(authService: context.read<AuthService>()),
        ),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
        Provider<MessagingService>(
          create: (BuildContext context) =>
              MessagingService(authService: context.read<AuthService>()),
        ),
      ],
      child: const SmartTaxInvoiceApp(),
    );
  }
}

class SmartTaxInvoiceApp extends StatelessWidget {
  const SmartTaxInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Tax & Invoice Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const LoginScreen(),
        );
      },
    );
  }
}

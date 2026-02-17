import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartTaxInvoiceApp();
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

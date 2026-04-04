import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/constants.dart';
import 'package:gopark_app/screens/auth/login_screen.dart';

void main() {
  runApp(const GoParkApp());
}

class GoParkApp extends StatelessWidget {
  const GoParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Pending: Add AuthProvider and other providers here
        Provider(create: (_) => 'Placeholder Provider'),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Later we will implement an auto-login check, for now, go straight to LoginScreen
        home: const LoginScreen(),
      ),
    );
  }
}

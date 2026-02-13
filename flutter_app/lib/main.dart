import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/credit_service.dart';
import 'services/purchase_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();

  if (AuthService.instance.isLoggedIn) {
    CreditService.instance.refresh();
    PurchaseService.instance.init();
  }

  runApp(const MouseTrapApp());
}

class MouseTrapApp extends StatelessWidget {
  const MouseTrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MouseTrap',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: AuthService.instance.isLoggedIn
          ? (AuthService.instance.onboardingSeen
              ? const HomeScreen()
              : const OnboardingScreen())
          : const LoginScreen(),
    );
  }
}

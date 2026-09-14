import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_routes.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/auth/presentation/sign_up_screen.dart';
import 'features/auth/presentation/verify_phone_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AuthRoutes.welcome,
      routes: {
        AuthRoutes.welcome: (_) => const WelcomeScreen(),
        AuthRoutes.signUp: (_) => const SignUpScreen(),
        AuthRoutes.verifyPhone: (_) => const VerifyPhoneScreen(),
        AuthRoutes.signIn: (_) => const SignInScreen(),
      },
    );
  }
}

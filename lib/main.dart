import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Views/auth/login.dart';
import 'Views/home.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Consult by Reed Code',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final token = await _authService.getToken();
    final user = await _authService.getCurrentUser();
    if (!mounted) return;

    if (token != null && user != null) {
      Get.off(() => const HomeView());
    } else {
      Get.off(() => const LoginView());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 80,
                color: AppTheme.primaryCyanDark,
              ),
              const SizedBox(height: 24),
              Text(
                'Consult by Reed Code',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.textCyan800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

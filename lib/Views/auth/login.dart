import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../home.dart';
import 'register.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Navigasi ke home menggunakan GetX
      Get.off(() => const HomeView(), transition: Transition.fadeIn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.string(
                '''
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 300">
                    <defs>
                      <linearGradient id="cyanGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" style="stop-color:#00CCCC;stop-opacity:1" />
                        <stop offset="100%" style="stop-color:#00FFFF;stop-opacity:1" />
                      </linearGradient>
                    </defs>
                  
                    <!-- Main text -->
                    <text x="300" y="150" font-family="Arial, sans-serif" font-size="72" font-weight="bold" fill="url(#cyanGradient)" text-anchor="middle" dominant-baseline="middle">Mind Mender</text>
                  
                    <!-- Heartbeat line -->
                    <path d="M75,220 L120,220 L142,175 L165,265 L187,220 L210,220" fill="none" stroke="#00CCCC" stroke-width="6" stroke-linecap="round"/>
                    
                    <!-- Brain icon -->
                    <path d="M510,220 C525,205 540,205 540,220 C540,235 525,235 525,220 C525,205 510,205 510,220 Z" fill="none" stroke="#00CCCC" stroke-width="4.5"/>
                    
                    <!-- Stethoscope icon -->
                    <circle cx="570" cy="220" r="9" fill="#00CCCC"/>
                    <path d="M555,220 Q562.5,205 570,220" fill="none" stroke="#00CCCC" stroke-width="4.5" stroke-linecap="round"/>
                </svg>
                ''',
                height: 150,
              ),
              const SizedBox(height: 48),
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.cyan[300]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  prefixIcon: Icon(Icons.lock, color: Colors.cyan[300]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.cyan[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const RegisterView()));
                },
                child: Text(
                  'Belum punya akun? Daftar disini',
                  style: TextStyle(color: Colors.cyan[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

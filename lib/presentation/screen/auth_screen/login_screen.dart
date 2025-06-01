import 'dart:convert';
import 'dart:developer';

import 'package:pos/core/utils/config.dart';
import 'package:pos/presentation/screen/splash_screen/splash_screen_2.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:pos/data/api/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        final loginResponse = await authService.login(
          _emailController.text,
          _passwordController.text,
        );

        print("DEBUG: loginResponse = $loginResponse");

        if (loginResponse != null) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Ambil token dari response
          String token = loginResponse.containsKey('token')
              ? loginResponse['token']
              : loginResponse['fullName'];

          String fullName = loginResponse['fullName'];

          String role = loginResponse['role'];

          final roles = jsonDecode(role)['data']['roles'];

          log(roles.toString());
          final hasSalesUser =
              roles.any((r) => r['role'] == 'API Self Profile');

          if (roles.isNotEmpty) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('roles', jsonEncode(roles));
          }

          if (fullName.isNotEmpty) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('full_name', fullName);
          }

          // Ambil SID dari cookie response
          String? sid;
          if (loginResponse.containsKey('sid')) {
            sid = loginResponse['sid'];
          }

          if (token.isNotEmpty) {
            await authProvider.setToken(token);

            // Simpan SID ke SharedPreferences
            if (sid != null && sid.isNotEmpty) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('sid', sid);
              print("SID saved: $sid");
            }

            if (context.mounted) {
              if (!hasSalesUser) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anda tidak punya akses login')),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen2()),
                );
              }
            }
          } else {
            print("Login gagal: Token tidak ditemukan");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Login gagal: Token tidak ditemukan')),
            );
          }
        } else {
          print("DEBUG: Login response null");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        print("Exception: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _exitApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            ConfigService.logo,
            width: 250,
          ),

          const SizedBox(height: 32),

          // Teks Selamat Datang
          Text(
            "Selamat Datang",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Teks Silahkan Login
          Text(
            "Silahkan login untuk melanjutkan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 48),

          // Email Field
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "example@gmail.com",
              labelText: "Email",
              labelStyle: TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              prefixIcon:
                  Icon(Icons.email_outlined, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),

          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "*********",
              labelText: "Password",
              labelStyle: TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tombol Login
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF533F77),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Tombol Exit App
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _exitApp,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.redAccent,
              ),
              child: Text(
                "Exit App",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // App Version
          const SizedBox(height: 24),
          Text(
            _appVersion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await Future.delayed(const Duration(seconds: 2));

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Bar dengan tombol kembali
              SizedBox(
                width: double.infinity,
                height: 60,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const StartScreen()),
                        );
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Daftar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Konten halaman register
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Buat Akun Baru",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Silahkan daftar untuk melanjutkan",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 32),

                          // TextField untuk Nama
                          CustomTextField(
                            controller: _nameController,
                            hintText: "Nama Lengkap",
                            labelText: "Nama",
                            isPassword: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Nama tidak boleh kosong";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // TextField untuk Email
                          CustomTextField(
                            controller: _emailController,
                            hintText: "example@gmail.com",
                            labelText: "Email",
                            isPassword: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Email tidak boleh kosong";
                              if (!value.contains('@')) return "Email harus mengandung '@'";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // TextField untuk No HP
                          CustomTextField(
                            controller: _phoneController,
                            hintText: "08XXXXXXXXXX",
                            labelText: "No HP",
                            isPassword: false,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "No HP tidak boleh kosong";
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) return "No HP hanya boleh angka";
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // TextField untuk Password
                          CustomTextField(
                            controller: _passwordController,
                            hintText: "*********",
                            labelText: "Password",
                            isPassword: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Password tidak boleh kosong";
                              if (value.length < 6) return "Password minimal 6 karakter";
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tombol Daftar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F3A5F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                "Daftar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

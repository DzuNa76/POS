import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Widget? suffixIcon; // Tambahkan parameter ini agar mendukung ikon
  final TextInputType keyboardType; // Tambahkan parameter ini untuk jenis input

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    this.isPassword = false,
    this.validator,
    this.suffixIcon, // Tambahkan parameter ini
    this.keyboardType = TextInputType.text, // Inisialisasi default
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType, // Gunakan keyboardType
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon, // Gunakan suffixIcon jika ada
      ),
      validator: validator, // Gunakan validator jika ada
    );
  }
}

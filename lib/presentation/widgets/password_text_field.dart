import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;

  const PasswordTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.labelText,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscured = true;

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      labelText: widget.labelText,
      isPassword: _isObscured,
      suffixIcon: IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: _toggleVisibility,
      ),
    );
  }
}

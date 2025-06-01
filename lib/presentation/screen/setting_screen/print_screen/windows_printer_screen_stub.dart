// lib/presentation/screen/setting_screen/print_screen/windows_printer_screen_stub.dart
import 'package:flutter/material.dart';

class WindowsPrinterScreen extends StatelessWidget {
  const WindowsPrinterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Printer USB tidak didukung di platform ini')),
    );
  }
}

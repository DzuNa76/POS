// lib/presentation/screen/setting_screen/print_screen/web_printer_screen_stub.dart
import 'package:flutter/material.dart';

class PrinterServiceWeb {
  Future<void> requestPort(BuildContext context) async {
    throw UnsupportedError('Web Serial API tidak didukung pada platform ini.');
  }

  Future<void> printTest(BuildContext context) async {
    throw UnsupportedError('Web Serial API tidak didukung pada platform ini.');
  }
}

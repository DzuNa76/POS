import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Impor screen untuk masing-masing platform
import 'print_screen/android_printer_screen.dart';
import 'print_screen/windows_printer_screen.dart'
if (dart.library.html) 'print_screen/windows_printer_screen_stub.dart';
import 'print_screen/web_printer_screen.dart';

class SettingPrinterScreen extends StatefulWidget {
  final bool removeAppBar;

  const SettingPrinterScreen({Key? key, this.removeAppBar = false}) : super(key: key);

  @override
  State<SettingPrinterScreen> createState() => _SettingPrinterScreenState();
}

class _SettingPrinterScreenState extends State<SettingPrinterScreen> {
  @override
  Widget build(BuildContext context) {
    Widget screen;

    if (kIsWeb) {
      screen = WebPrinterScreen(removeAppBar: widget.removeAppBar);
    } else if (Platform.isAndroid || Platform.isIOS) {
      screen = AndroidPrinterScreen(removeAppBar: widget.removeAppBar);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      screen = WindowsPrinterScreen(removeAppBar: widget.removeAppBar);
    } else {
      screen = const Scaffold(
        body: Center(child: Text("Platform tidak didukung")),
      );
    }

    return screen;
  }
}

// lib/presentation/screen/web_printer_screen.dart
import 'package:flutter/material.dart';
import 'printer_service_web_conditional.dart';

class WebPrinterScreen extends StatefulWidget {
  const WebPrinterScreen({super.key, this.removeAppBar = false});
  final bool removeAppBar;

  @override
  State<WebPrinterScreen> createState() => _WebPrinterScreenState();
}

class _WebPrinterScreenState extends State<WebPrinterScreen> {
  final PrinterServiceWeb _printerService = PrinterServiceWeb();

  @override
  Widget build(BuildContext context) {
    // Cek ukuran layar untuk menentukan apakah AppBar harus ditampilkan
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    bool shouldRemoveAppBar = widget.removeAppBar || isLargeScreen;

    return Scaffold(
      appBar: shouldRemoveAppBar ? null : AppBar(
        title: const Text('Pengaturan Printer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await _printerService.requestPort(context);
              },
              icon: const Icon(Icons.usb),
              label: const Text('Pilih Port Serial'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _printerService.printTest(context);
              },
              child: const Text('Test Print'),
            ),
          ],
        ),
      ),
    );
  }
}

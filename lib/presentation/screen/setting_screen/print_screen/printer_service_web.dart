// lib/presentation/screen/setting_screen/printer_service_web.dart
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class PrinterServiceWeb {
  dynamic _selectedPort;
  bool _isPrinting = false;

  /// Meminta pengguna memilih port serial menggunakan Web Serial API
  Future<void> requestPort(BuildContext context) async {
    try {
      if (js_util.hasProperty(html.window.navigator, 'serial')) {
        final serial = js_util.getProperty(html.window.navigator, 'serial');
        _selectedPort = await js_util.promiseToFuture(
          js_util.callMethod(serial, 'requestPort', []),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Port berhasil dipilih')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Web Serial API tidak didukung oleh browser ini.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan port: $e')),
      );
    }
  }

  /// Fungsi untuk mencetak struk dummy dengan perintah ESC/POS
  Future<void> printTest(BuildContext context) async {
    if (_selectedPort == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih port terlebih dahulu')),
      );
      return;
    }
    if (_isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer sedang digunakan, mohon tunggu...')),
      );
      return;
    }
    _isPrinting = true;
    try {
      // Buka port dengan konfigurasi (misal baudRate: 9600)
      await js_util.promiseToFuture(
        js_util.callMethod(_selectedPort, 'open', [js_util.jsify({'baudRate': 9600})]),
      );
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];
      bytes += generator.text(
        'VERNON SUKSES MAKMUR',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      bytes += generator.text(
        'Jl. Contoh No. 123, Kota',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.text('Item 1      x1  Rp10.000');
      bytes += generator.text('Item 2      x2  Rp20.000');
      bytes += generator.hr();
      bytes += generator.text(
        'TOTAL:      Rp30.000',
        styles: const PosStyles(align: PosAlign.right, bold: true),
      );
      bytes += generator.feed(1);
      final data = Uint8List.fromList(bytes);
      final writableStream = js_util.getProperty(_selectedPort, 'writable');
      final writer = js_util.callMethod(writableStream, 'getWriter', []);
      await js_util.promiseToFuture(
        js_util.callMethod(writer, 'write', [data]),
      );
      await js_util.promiseToFuture(
        js_util.callMethod(writer, 'releaseLock', []),
      );
      await js_util.promiseToFuture(
        js_util.callMethod(_selectedPort, 'close', []),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cetak berhasil via Web Serial!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak via Web: $e')),
      );
    } finally {
      _isPrinting = false;
    }
  }
}

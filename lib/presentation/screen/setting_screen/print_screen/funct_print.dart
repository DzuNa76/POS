import 'dart:io'; // Untuk deteksi platform
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:print_usb/print_usb.dart';
import '../../../../core/providers/print_state.dart';
import '../../../widgets/notification.dart';

Future<void> printReceipt(
    BuildContext context,
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> orderItems) async {
  try {
    if (PrintState.connectedPrinter == null &&
        PrintState.connectedUsbPrinter == null) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Tidak ada printer yang terhubung.",
        icon: Icons.error,
        iconColor: Colors.red,
        confirmText: "OK",
      );
      return;
    }

    // 🎯 Tentukan ukuran kertas dan konfigurasi pencetakan
    final profile = await CapabilityProfile.load();
    PaperSize paperSize = PaperSize.mm80;
    String? selectedPaper = PrintState.selectedPaperSize;
    if (selectedPaper == '58mm') {
      paperSize = PaperSize.mm58;
    } else if (selectedPaper == '72mm') {
      paperSize = PaperSize.mm72;
    }

    // Sesuaikan panjang baris, ukuran teks, dan tipe font sesuai ukuran kertas
    int hrLength;
    PosTextSize textSize;
    PosFontType fontType;
    if (selectedPaper == '58mm') {
      hrLength = 32;
      textSize = PosTextSize.size1;
      fontType = PosFontType.fontB;
    } else if (selectedPaper == '72mm') {
      hrLength = 42;
      textSize = PosTextSize.size1;
      fontType = PosFontType.fontA;
    } else {
      hrLength = 48;
      textSize = PosTextSize.size1;
      fontType = PosFontType.fontA;
    }

    // ==== Fungsi Bantuan untuk Format Teks ====
    String formatLine(String label, String value, int hrLength) {
      int space = hrLength - label.length - value.length;
      space = space > 0 ? space : 1;
      return '$label${' ' * space}$value';
    }

    String dottedLine(int hrLength) {
      return '-' * hrLength;
    }

    String adaptiveCenter(String text, int hrLength) {
      // Potong teks jika melebihi batas
      String truncated =
          text.length > hrLength ? text.substring(0, hrLength) : text;
      int totalPadding = hrLength - truncated.length;
      int leftPadding = totalPadding ~/ 2;
      leftPadding = leftPadding > 0 ? leftPadding : 0;
      return '${' ' * leftPadding}$truncated';
    }

    // ==== Generate Data Struk ESC/POS ====
    final generator = Generator(paperSize, profile);
    List<int> receiptData = [];

    // Reset printer
    receiptData += generator.reset();

    // ----- Header -----
    receiptData += generator.text(
      adaptiveCenter('VERNON JAYA MAKMUR', hrLength),
      styles: PosStyles(
        align: PosAlign.left,
        fontType: fontType,
      ),
    );
    receiptData += generator.text(
      adaptiveCenter('MALANG - 1', hrLength),
      styles: PosStyles(
        align: PosAlign.left,
        fontType: fontType,
      ),
    );

    // Alamat
    String alamat1 =
        'Jl. MT. Haryono No.116, Ketawanggede, Kec. Lowokwaru, Malang';
    String alamat2 = '';
    if (selectedPaper == '58mm' && alamat1.length > hrLength) {
      List<String> addressParts = [];
      String temp = alamat1;
      while (temp.length > hrLength) {
        int splitPos = temp.substring(0, hrLength).lastIndexOf(' ');
        if (splitPos == -1) splitPos = hrLength;
        addressParts.add(temp.substring(0, splitPos));
        temp = temp.substring(splitPos).trim();
      }
      if (temp.isNotEmpty) {
        addressParts.add(temp);
      }
      for (String part in addressParts) {
        receiptData += generator.text(
          adaptiveCenter(part, hrLength),
          styles: PosStyles(
            align: PosAlign.left,
            fontType: fontType,
          ),
        );
      }
    } else {
      receiptData += generator.text(
        adaptiveCenter(alamat1, hrLength),
        styles: PosStyles(
          align: PosAlign.left,
          fontType: fontType,
        ),
      );
    }
    // Alamat baris kedua (jika ada)
    receiptData += generator.text(
      adaptiveCenter(alamat2, hrLength),
      styles: PosStyles(
        align: PosAlign.center,
        fontType: fontType,
      ),
    );

    // Tambahkan keterangan reprint
    receiptData += generator.text(
      adaptiveCenter('** Reprinted **', hrLength),
      styles: PosStyles(
        align: PosAlign.center,
        fontType: fontType,
      ),
    );

    // ----- Informasi Transaksi -----
    // Gunakan waktu saat ini untuk format konsisten
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy, HH:mm').format(now);
    String transactionNo =
        'POS-MLG-2-${DateFormat('yyyyMMdd').format(now)}-095306';

    receiptData += generator.text(
      formatLine('No', transactionNo, hrLength),
      styles: PosStyles(fontType: fontType),
    );
    receiptData += generator.text(
      formatLine('Dine in', formattedDate, hrLength),
      styles: PosStyles(fontType: fontType),
    );
    // Menggunakan field 'customerName' jika tersedia
    receiptData += generator.text(
      formatLine('Customer', transaction['customerName'] ?? '-', hrLength),
      styles: PosStyles(fontType: fontType),
    );
    receiptData += generator.text(
      formatLine('Kasir', transaction['cashierName'] ?? '-', hrLength),
      styles: PosStyles(fontType: fontType),
    );

    // Garis pembatas
    receiptData += generator.text(
      dottedLine(hrLength),
      styles: PosStyles(fontType: fontType),
    );

    // ----- Detail Pesanan -----
    for (var item in orderItems) {
      // Cetak nama produk
      receiptData += generator.text(
        item['name'],
        styles: PosStyles(fontType: fontType),
      );
      // Format baris dengan detail kuantitas dan harga
      String leftText = '${item['quantity']} x Rp ${item['price']}';
      String rightText = 'Rp ${item['price'] * item['quantity']}';
      receiptData += generator.text(
        formatLine(leftText, rightText, hrLength),
        styles: PosStyles(fontType: fontType),
      );
      // Jika ada keterangan tambahan (misalnya extra)
      if (item.containsKey('extra') &&
          item['extra'] != null &&
          item['extra'].toString().isNotEmpty) {
        receiptData += generator.text(
          '(+) ${item['extra']}',
          styles: PosStyles(fontType: fontType),
        );
        // Contoh: jika extra memiliki harga
        if (item.containsKey('extraPrice')) {
          String extraLine = formatLine('3 x Rp ${item['extraPrice']}',
              'Rp ${item['extraPrice'] * 3}', hrLength);
          receiptData += generator.text(
            extraLine,
            styles: PosStyles(fontType: fontType),
          );
        }
      }
    }

    // Garis pembatas
    receiptData += generator.text(
      dottedLine(hrLength),
      styles: PosStyles(fontType: fontType),
    );

    // ----- Total dan Pembayaran -----
    receiptData += generator.text(
      formatLine('TOTAL', 'Rp ${transaction['total']}', hrLength),
      styles: PosStyles(
        fontType: fontType,
        bold: true,
      ),
    );
    receiptData += generator.text(
      dottedLine(hrLength),
      styles: PosStyles(fontType: fontType),
    );
    if (transaction['paymentMethod'] == 'Tunai') {
      receiptData += generator.text(
        formatLine('Cash', 'Rp ${transaction['paid']}', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      receiptData += generator.text(
        formatLine('Change', 'Rp ${transaction['change']}', hrLength),
        styles: PosStyles(fontType: fontType),
      );
    }
    receiptData += generator.text(
      dottedLine(hrLength),
      styles: PosStyles(fontType: fontType),
    );

    // ----- Potong Kertas -----
    // receiptData += generator.cut(); // Uncomment jika printer mendukung cut

    // 🔍 Kirim data ke printer berdasarkan platform
    if (Platform.isWindows && PrintState.connectedUsbPrinter != null) {
      bool result = await PrintUsb.printBytes(
        device: PrintState.connectedUsbPrinter!,
        bytes: receiptData,
      );
      if (!result) {
        throw Exception('Gagal mencetak dengan printer USB');
      }
    } else if (Platform.isAndroid && PrintState.connectedPrinter != null) {
      await _printViaBluetooth(
          context, PrintState.connectedPrinter!, receiptData);
    }
    showCustomPopup(
      context: context,
      title: "Berhasil",
      message: "Struk berhasil dicetak.",
      confirmText: "OK",
      duration: 5,
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );
  } catch (e) {
    showCustomPopup(
      context: context,
      title: "Error",
      message: "Error saat mencetak: $e",
      confirmText: "OK",
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }
}

// Fungsi untuk mencetak via Bluetooth (Android)
Future<void> _printViaBluetooth(BuildContext context, BluetoothDevice printer,
    List<int> receiptData) async {
  try {
    if (!(await printer.isConnected)) {
      await printer.connect().timeout(const Duration(seconds: 5));
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    BluetoothCharacteristic? writeCharacteristic;
    List<BluetoothService> services = await printer.discoverServices();
    for (var service in services) {
      String serviceUuid = service.uuid.toString().toUpperCase();
      if (serviceUuid.contains("18F0") ||
          serviceUuid.contains("FF00") ||
          serviceUuid.contains("AE30") ||
          serviceUuid.contains("E7810A71") ||
          serviceUuid.contains("49535343")) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
      }
      if (writeCharacteristic != null) break;
    }
    if (writeCharacteristic == null) {
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }
    }
    if (writeCharacteristic == null) {
      showCustomPopup(
        context: context,
        title: "Error",
        message:
            "❌ Tidak menemukan karakteristik yang dapat digunakan untuk mencetak.",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    int chunkSize = 100;
    int totalChunks = (receiptData.length / chunkSize).ceil();
    for (int i = 0; i < receiptData.length; i += chunkSize) {
      int end = (i + chunkSize < receiptData.length)
          ? i + chunkSize
          : receiptData.length;
      List<int> chunk = receiptData.sublist(i, end);
      bool withoutResponse =
          writeCharacteristic.properties.writeWithoutResponse;
      await writeCharacteristic.write(Uint8List.fromList(chunk),
          withoutResponse: withoutResponse);
      await Future.delayed(Duration(milliseconds: 150));
    }
  } catch (e) {
    showCustomPopup(
      context: context,
      title: "Error",
      message: "❌ Gagal mencetak via Bluetooth: $e",
      confirmText: "OK",
    );
  }
}

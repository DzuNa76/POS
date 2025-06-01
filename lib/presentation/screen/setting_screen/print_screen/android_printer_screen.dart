import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/print_state.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/notification.dart';

class AndroidPrinterScreen extends StatefulWidget {
  const AndroidPrinterScreen({super.key, this.removeAppBar = false});

  final bool removeAppBar;

  @override
  State<AndroidPrinterScreen> createState() => _AndroidPrinterScreenState();
}

class _AndroidPrinterScreenState extends State<AndroidPrinterScreen> {
  final TextEditingController _ipController = TextEditingController();
  BluetoothDevice? _selectedPrinter;
  String? _selectedPaperSize;
  BluetoothDevice? _connectedPrinter;

  // Opsi ukuran kertas yang tersedia
  final List<String> _paperSizes = ['58mm', '72mm', '80mm'];

  // List printer yang ditemukan (dide-duplikasi berdasarkan device.id)
  List<BluetoothDevice> _bluetoothPrinters = [];

  @override
  void initState() {
    super.initState();
    // Pulihkan state jika ada printer tersambung secara global
    _connectedPrinter = PrintState.connectedPrinter;
    _selectedPaperSize = PrintState.selectedPaperSize;
    _scanBluetoothDevices();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  /// Memindai perangkat Bluetooth dan menyimpan daftar printer tanpa duplikasi.
  void _scanBluetoothDevices() async {
    try {
      //popup loading

      setState(() {
        _bluetoothPrinters.clear();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      FlutterBluePlus.scanResults.listen((results) {
        // Deduplikasi berdasarkan device.id
        final uniqueDevices = <String, BluetoothDevice>{};
        for (var result in results) {
          uniqueDevices[result.device.id.toString()] = result.device;
        }
        setState(() {
          _bluetoothPrinters = uniqueDevices.values.toList();
        });
      });
    } catch (e) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Gagal memindai perangkat. Pastikan Bluetooth Anda menyala.",
        confirmText: "OK",
        icon: Icons.error,
      );
    }
  }

  /// Menghubungkan ke printer Bluetooth dan menyimpannya di PrintState.
  Future<void> _connectToPrinter(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedPrinter = device;
      });
      // Simpan printer ke state global agar layar lain dapat mengaksesnya.
      PrintState.connectedPrinter = device;
      showCustomPopup(
        context: context,
        title: "Berhasil",
        message: "Printer ${device.name} berhasil terhubung!",
        confirmText: "OK",
        duration: 5,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (e) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Gagal menghubungkan ke ${device.name}",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  /// Menguji koneksi printer berdasarkan input IP (hanya notifikasi).
  void _testPrinterConnection() {
    final ipAddress = _ipController.text.trim();
    if (ipAddress.isEmpty) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Alamat printer tidak boleh kosong",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    showCustomPopup(
      context: context,
      title: "Berhasil",
      message: "Tes koneksi printer berhasil!",
      duration: 5,
      confirmText: "OK",
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );
  }

  /// Memutuskan koneksi printer dan membersihkan state global.
  Future<void> _disconnectPrinter() async {
    if (_connectedPrinter != null) {
      await _connectedPrinter!.disconnect();
      setState(() {
        _connectedPrinter = null;
      });
      PrintState.connectedPrinter = null;
    }
  }

  BluetoothDevice? _findDeviceInList(BluetoothDevice? device) {
    if (device == null || _bluetoothPrinters.isEmpty) {
      return null;
    }

    // Cari berdasarkan ID yang sama
    try {
      return _bluetoothPrinters
          .firstWhere((d) => d.id.toString() == device.id.toString());
    } catch (e) {
      // Jika tidak ditemukan, kembalikan null
      return null;
    }
  }

  /// Fungsi test print android
  void _printTest() async {
    if (_connectedPrinter == null && _selectedPaperSize == null) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Pilih printer dan ukuran kertas terlebih dahulu",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      BluetoothDevice selectedDevice = _connectedPrinter!;

      // Pastikan printer sudah dalam status connected
      final deviceState = await selectedDevice.state.first;
      if (deviceState != BluetoothDeviceState.connected) {
        await selectedDevice.connect();
      }

      // Temukan layanan dan karakteristik write
      List<BluetoothService> services = await selectedDevice.discoverServices();
      BluetoothCharacteristic? writeCharacteristic;

      // Cari karakteristik pada service dengan UUID yang umum digunakan oleh printer termal
      for (var service in services) {
        if (service.uuid.toString().toUpperCase().contains('1101') ||
            service.uuid.toString().toUpperCase().contains('18F0') ||
            service.uuid.toString().toUpperCase().contains('FF00')) {
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

      // Jika belum ditemukan, cari di seluruh service
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
        print('Karakteristik write tidak ditemukan');
        return;
      }

      // Load profile printer dan tentukan ukuran kertas berdasarkan pilihan.
      final profile = await CapabilityProfile.load();
      PaperSize paperSize;
      int hrLength;
      PosTextSize textSize;
      PosFontType fontType;

      // Menentukan ukuran kertas dan batas karakter
      switch (_selectedPaperSize) {
        case '58mm':
          paperSize = PaperSize.mm58;
          hrLength = 32;
          textSize = PosTextSize.size1;
          fontType = PosFontType.fontB;
          break;
        case '72mm':
          paperSize = PaperSize.mm72;
          hrLength = 42;
          textSize = PosTextSize.size1;
          fontType = PosFontType.fontA;
          break;
        default:
          paperSize = PaperSize.mm80;
          hrLength = 48;
          textSize = PosTextSize.size1;
          fontType = PosFontType.fontA;
          break;
      }

      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      // Reset printer
      bytes += generator.reset();

      // Fungsi untuk membuat format baris dengan item di kiri dan nilai di kanan
      String formatLine(String label, String value, int hrLength) {
        int space = hrLength - label.length - value.length;
        space = space > 0 ? space : 1;
        return '$label${' ' * space}$value';
      }

      // Fungsi untuk garis putus-putus
      String dottedLine(int hrLength) {
        return '-' * hrLength;
      }

      // Fungsi untuk center text yang menyesuaikan ukuran kertas
      String adaptiveCenter(String text, int hrLength) {
        // Jika teks lebih panjang dari batas, potong
        String truncated =
            text.length > hrLength ? text.substring(0, hrLength) : text;

        // Hitung padding kiri untuk pemusatan
        int totalPadding = hrLength - truncated.length;
        int leftPadding = totalPadding ~/ 2;
        leftPadding = leftPadding > 0 ? leftPadding : 0;

        // Kembalikan teks yang sudah dipotong dan diposisikan di tengah
        return '${' ' * leftPadding}$truncated';
      }

      // ===== KODE CETAK HEADER =====

      bytes += generator.text(
        adaptiveCenter('VERNON JAYA MAKMUR', hrLength),
        styles: PosStyles(
          align: PosAlign.left,
          fontType: fontType,
        ),
      );

      // Cetak kode cabang
      bytes += generator.text(
        adaptiveCenter('MALANG - 1', hrLength),
        styles: PosStyles(
          align: PosAlign.left,
          fontType: fontType,
        ),
      );

      // Cetak alamat dengan adaptasi untuk kertas kecil
      String alamat1 =
          'Jl. MT. Haryono No.116, Ketawanggede, Kec. Lowokwaru, Malang';
      String alamat2 = '';

      if (_selectedPaperSize == '58mm' && alamat1.length > hrLength) {
        // Pecah alamat menjadi beberapa bagian
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

        // Cetak bagian-bagian alamat
        for (String part in addressParts) {
          bytes += generator.text(
            adaptiveCenter(part, hrLength),
            styles: PosStyles(
              align: PosAlign.left,
              fontType: fontType,
            ),
          );
        }
      } else {
        // Cetak alamat normal untuk kertas lebar
        bytes += generator.text(
          adaptiveCenter(alamat1, hrLength),
          styles: PosStyles(
            align: PosAlign.left,
            fontType: fontType,
          ),
        );
      }

      // Cetak alamat baris 2
      bytes += generator.text(
        adaptiveCenter(alamat2, hrLength),
        styles: PosStyles(
          align: PosAlign.center,
          fontType: fontType,
        ),
      );

      // Tambahkan Reprinted jika perlu
      bytes += generator.text(
        adaptiveCenter('** Reprinted **', hrLength),
        styles: PosStyles(
          align: PosAlign.center,
          fontType: fontType,
        ),
      );

      // ==== KODE UNTUK LANJUTAN STRUK ====

      // Informasi transaksi
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd-MM-yyyy, HH:mm').format(now);
      String transactionNo =
          'POS-MLG-2-${DateFormat('yyyyMMdd').format(now)}-095306';

      bytes += generator.text(
        formatLine('No', transactionNo, hrLength),
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('Dine in', formattedDate, hrLength),
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('Customer', 'Ka Fahmi', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('Kasir', 'Agil', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Garis pembatas
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Format item standar (nama produk di kiri, total harga di kanan)
      bytes += generator.text(
        'Caffe Americano - Hot',
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('1 x IDR 21.000', 'IDR 21.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Format item extra dengan indentasi
      bytes += generator.text(
        '(+) Extra Espresso 1 Shot',
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('3 x IDR 4.000', 'IDR 12.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Item kedua
      bytes += generator.text(
        'Croffle Beef BBQ Mushroom',
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('1 x IDR 26.000', 'IDR 26.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Garis pembatas
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Total
      bytes += generator.text(
        formatLine('TOTAL', 'IDR 59.000', hrLength),
        styles: PosStyles(
          fontType: fontType,
          bold: true,
        ),
      );

      // Garis pembatas
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Informasi pembayaran
      bytes += generator.text(
        formatLine('Cash', 'IDR 100.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      bytes += generator.text(
        formatLine('Change', 'IDR 41.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Garis pembatas
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Akhiri dengan potong kertas
      // bytes += generator.cut();

      // Kirim sebagian data sekaligus ke printer
      if (writeCharacteristic.properties.writeWithoutResponse) {
        // Break data into smaller chunks (e.g., 512 bytes or less)
        final chunkSize = 400;
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          await writeCharacteristic.write(chunk, withoutResponse: true);
          // Add a small delay between chunks
          await Future.delayed(const Duration(milliseconds: 20));
        }
      } else {
        // Break data into smaller chunks (e.g., 512 bytes or less)
        final chunkSize = 512;
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          await writeCharacteristic.write(chunk);
          // Add a small delay between chunks
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Cetak berhasil
      showCustomPopup(
        context: context,
        title: "Berhasil",
        message: "Cetak berhasil!",
        confirmText: "OK",
        icon: Icons.check_circle,
        iconColor: Colors.green,
        duration: 5,
      );
    } catch (e) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Gagal mencetak: $e",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan nilai dropdown printer sesuai dengan printer yang tersambung
    BluetoothDevice? dropdownValue;
    if (_connectedPrinter != null &&
        _bluetoothPrinters.any((d) => d.id == _connectedPrinter!.id)) {
      dropdownValue =
          _bluetoothPrinters.firstWhere((d) => d.id == _connectedPrinter!.id);
    }

    // Cek ukuran layar untuk menentukan apakah AppBar harus ditampilkan
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    bool shouldRemoveAppBar = widget.removeAppBar || isLargeScreen;

    return Scaffold(
      appBar: shouldRemoveAppBar
          ? null
          : AppBar(
              title: const Text('Pengaturan Printer'),
              centerTitle: true,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alamat Printer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _ipController,
              hintText: 'Masukkan alamat IP printer',
              labelText: 'Alamat IP Printer',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testPrinterConnection,
                child: const Text('Test Koneksi'),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Printer Terhubung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _connectedPrinter == null ? _scanBluetoothDevices : null,
                child: const Text('Pindai Printer Bluetooth'),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BluetoothDevice>(
              decoration: const InputDecoration(
                labelText: 'Daftar Printer Bluetooth',
                border: OutlineInputBorder(),
              ),
              items: _bluetoothPrinters.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(
                    device.name.isNotEmpty ? device.name : device.id.toString(),
                  ),
                );
              }).toList(),
              onChanged: _connectedPrinter == null
                  ? (device) {
                      if (device != null) {
                        _connectToPrinter(device);
                      }
                    }
                  : null, // Set null ketika printer sudah terhubung untuk menonaktifkan dropdown
              value: _findDeviceInList(_connectedPrinter),
              hint: _connectedPrinter != null
                  ? Text(_connectedPrinter!.name.isNotEmpty
                      ? _connectedPrinter!.name
                      : _connectedPrinter!.id.toString())
                  : const Text('Pilih printer'),
            ),
            const SizedBox(height: 8),
            if (_connectedPrinter != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _disconnectPrinter,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Putuskan Koneksi'),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Ukuran Kertas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Ukuran Kertas',
                border: OutlineInputBorder(),
              ),
              items: _paperSizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaperSize = value;
                });
                PrintState.selectedPaperSize = value;
              },
              value: _selectedPaperSize,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _printTest,
                child: const Text('Test Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

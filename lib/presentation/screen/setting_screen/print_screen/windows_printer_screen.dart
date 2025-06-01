import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:print_usb/model/usb_device.dart';
import 'package:print_usb/print_usb.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan import ini
import '../../../../core/providers/print_state.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/notification.dart';

class WindowsPrinterScreen extends StatefulWidget {
  const WindowsPrinterScreen({super.key, this.removeAppBar = false});
  final bool removeAppBar;

  @override
  State<WindowsPrinterScreen> createState() => _WindowsPrinterScreenState();
}

class _WindowsPrinterScreenState extends State<WindowsPrinterScreen> {
  List<UsbDevice> devices = [];
  UsbDevice? _selectedDevice;
  final TextEditingController _ipController = TextEditingController();
  String? _selectedPaperSize;
  List<String> _paperSizes = ['58mm', '72mm', '80mm'];

  // Variabel untuk menyimpan nama printer USB yang tersimpan
  String? _savedUsbName;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load data yang tersimpan
    _scanUsbPrinters();
  }

  // Fungsi untuk memuat data dari SharedPreferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPaperSize =
          prefs.getString('selectedPaperSize') ?? _paperSizes[0];
      _savedUsbName = prefs.getString('selectedUsbName');
      // Set ke PrintState jika diperlukan
      PrintState.selectedPaperSize = _selectedPaperSize;
    });
  }

  // Fungsi untuk menyimpan data ke SharedPreferences
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_selectedPaperSize != null) {
      await prefs.setString('selectedPaperSize', _selectedPaperSize!);
    }
    if (_selectedDevice != null) {
      await prefs.setString('selectedUsbName', _selectedDevice!.name);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  /// Fungsi untuk mendapatkan daftar printer USB yang terhubung
  void _scanUsbPrinters() async {
    try {
      List<UsbDevice> newDevices = await PrintUsb.getList();
      setState(() {
        devices = newDevices;

        // Jika ada saved USB name, cari di daftar perangkat
        if (_savedUsbName != null) {
          final matchedDevice = devices.firstWhere(
            (device) => device.name == _savedUsbName,
          );
          if (matchedDevice != null) {
            _selectedDevice = matchedDevice;
            PrintState.connectedUsbPrinter = matchedDevice;
          }
        }

        // Jika sudah ada printer terpilih, pastikan masih ada di daftar
        if (_selectedDevice != null) {
          bool deviceStillExists = devices.any(
            (device) => device.name == _selectedDevice!.name,
          );
          if (!deviceStillExists) {
            _selectedDevice = null;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context: context,
          title: "Error",
          message: "Gagal mendapatkan daftar printer: $e",
          confirmText: "OK",
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  /// Mendeteksi koneksi printer USB atau IP
  void _testPrinterConnection() {
    final ipAddress = _ipController.text.trim();
    if (ipAddress.isEmpty && _selectedDevice == null) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Alamat printer atau perangkat USB harus dipilih",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // Simpan data ukuran kertas ke PrintState dan SharedPreferences
    PrintState.selectedPaperSize = _selectedPaperSize;
    _saveSettings();

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

  /// Fungsi untuk mencetak uji coba windows
  void _printTest() async {
    if (_selectedDevice == null && _selectedPaperSize == null) {
      showCustomPopup(
        context: context,
        title: "Error",
        message: "Pilih printer USB dan ukuran kertas terlebih dahulu",
        confirmText: "OK",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      // Pastikan printer terhubung
      bool isConnected = await PrintUsb.connect(name: _selectedDevice!.name);
      if (!isConnected) {
        showCustomPopup(
          context: context,
          title: "Error",
          message: "Gagal terhubung ke printer USB",
          confirmText: "OK",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      // Simpan data printer yang terhubung dan ukuran kertas
      PrintState.connectedUsbPrinter = _selectedDevice;
      PrintState.selectedPaperSize = _selectedPaperSize;
      _saveSettings();

      // Menentukan ukuran kertas dan batas karakter
      final profile = await CapabilityProfile.load();
      PaperSize paperSize;
      int hrLength;
      PosTextSize textSize;
      PosFontType fontType;

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
          bytes += generator.text(
            adaptiveCenter(part, hrLength),
            styles: PosStyles(
              align: PosAlign.left,
              fontType: fontType,
            ),
          );
        }
      } else {
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

      // ==== LANJUTAN STRUK CETAK ====
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
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        'Caffe Americano - Hot',
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('1 x IDR 21.000', 'IDR 21.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        '(+) Extra Espresso 1 Shot',
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('3 x IDR 4.000', 'IDR 12.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        'Croffle Beef BBQ Mushroom',
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('1 x IDR 26.000', 'IDR 26.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('TOTAL', 'IDR 59.000', hrLength),
        styles: PosStyles(
          fontType: fontType,
          bold: true,
        ),
      );
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('Cash', 'IDR 100.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        formatLine('Change', 'IDR 41.000', hrLength),
        styles: PosStyles(fontType: fontType),
      );
      bytes += generator.text(
        dottedLine(hrLength),
        styles: PosStyles(fontType: fontType),
      );

      // Mengirim data ke printer
      bool printResult = await PrintUsb.printBytes(
        device: _selectedDevice!,
        bytes: bytes,
      );

      if (!printResult) {
        throw Exception('Gagal mengirim data ke printer');
      }

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat Printer (Opsional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _ipController,
                  hintText: 'Masukkan alamat IP atau port printer',
                  labelText: '',
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
                const SizedBox(height: 16),
                const Text(
                  'Pilih Printer USB',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UsbDevice>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Text(device.name),
                    );
                  }).toList(),
                  onChanged: (device) async {
                    if (device != null) {
                      try {
                        bool result = await PrintUsb.connect(name: device.name);
                        if (result) {
                          setState(() {
                            _selectedDevice = device;
                            PrintState.connectedUsbPrinter = device;
                          });
                          _saveSettings();
                          showCustomPopup(
                            context: context,
                            title: "Berhasil",
                            message: "Printer USB berhasil terhubung",
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                            duration: 5,
                          );
                        } else {
                          showCustomPopup(
                            context: context,
                            title: "Error",
                            message: "Gagal terhubung ke ${device.name}",
                            confirmText: "OK",
                            icon: Icons.error,
                            iconColor: Colors.red,
                          );
                        }
                      } catch (e) {
                        showCustomPopup(
                          context: context,
                          title: "Error",
                          message: "Gagal terhubung ke ${device.name}: $e",
                          confirmText: "OK",
                          icon: Icons.error,
                          iconColor: Colors.red,
                        );
                      }
                    }
                  },
                  value: devices.contains(_selectedDevice)
                      ? _selectedDevice
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ukuran Kertas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _paperSizes.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaperSize = value;
                        PrintState.selectedPaperSize = value;
                      });
                      _saveSettings();
                    }
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
          );
        },
      ),
    );
  }
}

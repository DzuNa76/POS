import 'package:flutter/material.dart';
import 'package:pos/presentation/screen/setting_screen/setting_interface_screen.dart';
import 'package:pos/presentation/screen/setting_screen/setting_printer_screen.dart';
import 'package:pos/presentation/screen/setting_screen/setting_application_screen.dart';
import 'package:pos/presentation/screen/setting_screen/setting_discount_screen.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Widget? _selectedSetting; // Untuk menyimpan tampilan isi pengaturan di tablet

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >=
            600; // Jika layar >= 600px, anggap sebagai tablet

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengaturan'),
            centerTitle: true,
          ),
          drawer:
              const SidebarMenu(), // Sidebar tetap muncul di semua perangkat
          body: isTablet
              ? Row(
                  children: [
                    // Sidebar tetap ada di kiri
                    SizedBox(
                      width: 350, // Lebar sidebar
                      child: _buildSettingsList(isTablet),
                    ),
                    const VerticalDivider(width: 1), // Garis pemisah
                    // Bagian kanan untuk isi pengaturan
                    Expanded(
                      child: _selectedSetting ??
                          const Center(
                            child: Text(
                              "Pilih pengaturan di sebelah kiri",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                    ),
                  ],
                )
              : _buildSettingsList(
                  isTablet), // Jika mode HP, tetap navigasi ke halaman baru
        );
      },
    );
  }

  // Widget daftar pengaturan (Sidebar)
  Widget _buildSettingsList(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Pengaturan:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Tombol untuk Setting Aplikasi
          ListTile(
            leading: const Icon(Icons.app_settings_alt),
            title: const Text('Aplikasi'),
            onTap: () => _onSettingSelected(
                SettingApplicationScreen(removeAppBar: isTablet), isTablet),
          ),
          const Divider(),
          // Tombol untuk Setting Printer
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Printer'),
            onTap: () => _onSettingSelected(
                SettingPrinterScreen(removeAppBar: isTablet), isTablet),
          ),
          const Divider(),
          // Tombol untuk Setting Interface
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Interface'),
            onTap: () => _onSettingSelected(
                SettingsInterfaceScreen(removeAppBar: isTablet), isTablet),
          ),
          const Divider(),
          // Tombol untuk Setting Diskon
          ListTile(
            leading: const Icon(Icons.discount),
            title: const Text('Diskon'),
            onTap: () => _onSettingSelected(
                SettingDiscountScreen(removeAppBar: isTablet), isTablet),
          ),
          const Divider(),
        ],
      ),
    );
  }

  // Fungsi untuk menangani pemilihan pengaturan
  void _onSettingSelected(Widget screen, bool isTablet) {
    if (isTablet) {
      setState(() {
        _selectedSetting = screen; // Tampilkan isi pengaturan di panel kanan
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
}

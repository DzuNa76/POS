import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class SettingApplicationScreen extends StatefulWidget {
  const SettingApplicationScreen({Key? key, this.removeAppBar = false})
      : super(key: key);

  final bool removeAppBar;

  @override
  State<SettingApplicationScreen> createState() =>
      _SettingApplicationScreenState();
}

class _SettingApplicationScreenState extends State<SettingApplicationScreen> {
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _posNameController = TextEditingController();
  String? _selectedOutlet;
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    // Cek ukuran layar untuk menentukan apakah AppBar harus ditampilkan
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;
    bool shouldRemoveAppBar = widget.removeAppBar || isLargeScreen;

    return Scaffold(
      appBar: shouldRemoveAppBar
          ? null
          : AppBar(
              title: const Text('Pengaturan Aplikasi'),
              centerTitle: true,
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Outlet Section
            const Text(
              'Outlet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Silahkan pilih outlet'),
            const SizedBox(height: 8),
            DropdownField(
              label: 'Pilih Outlet',
              items: ['Outlet 1', 'Outlet 2', 'Outlet 3'], // Data dummy
              onChanged: (value) {
                setState(() {
                  _selectedOutlet = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(),

            // License Device POS Section
            const Text(
              'License Device POS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
                'Silahkan mengisi license device POS yang sudah diberikan oleh Administrator'),
            const SizedBox(height: 8),
            PasswordTextField(
              controller: _licenseController,
              hintText: 'Masukkan license device POS',
              labelText: 'License Device POS',
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Logika tombol, contoh validasi atau simpan license
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48), // Lebar penuh
              ),
              child: const Text('Verifikasi License'),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Nama POS Section
            const Text(
              'Nama POS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Nama POS yang terdaftar oleh sistem'),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _posNameController,
              hintText: 'Masukkan nama POS',
              labelText: 'Nama POS',
            ),
            const SizedBox(height: 8),
            Text(
              _isSaved ? 'Data sudah disimpan' : 'Data belum disimpan',
              style: TextStyle(
                color: _isSaved ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Simpan dan Reset
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSaved = true;
                });
                // Logika penyimpanan data
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48), // Lebar penuh
              ),
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _licenseController.clear();
                  _posNameController.clear();
                  _selectedOutlet = null;
                  _isSaved = false;
                });
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48), // Lebar penuh
              ),
              child: const Text('Reset Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}

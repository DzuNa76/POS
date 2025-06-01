import 'package:flutter/material.dart';
import 'package:pos/core/providers/discount_provider.dart';
import 'package:provider/provider.dart';

import '../../widgets/notification.dart';

class SettingDiscountScreen extends StatefulWidget {
  final bool removeAppBar;

  const SettingDiscountScreen({Key? key, this.removeAppBar = false})
      : super(key: key);

  @override
  State<SettingDiscountScreen> createState() => _SettingDiscountScreenState();
}

class _SettingDiscountScreenState extends State<SettingDiscountScreen> {
  final TextEditingController _maxDiscountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<DiscountSettingsProvider>(context, listen: false);
      _maxDiscountController.text = provider.maxDiscountPercentage.toString();
    });
  }

  @override
  void dispose() {
    _maxDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.removeAppBar
          ? null
          : AppBar(
              title: const Text('Pengaturan Diskon'),
              centerTitle: true,
            ),
      body: Consumer<DiscountSettingsProvider>(
        builder: (context, discountSettings, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atur Diskon:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Switch untuk mengaktifkan/menonaktifkan diskon
                SwitchListTile(
                  title: const Text('Aktifkan Diskon'),
                  subtitle: const Text('Gunakan fitur diskon pada aplikasi.'),
                  value: discountSettings.isDiscountEnabled,
                  onChanged: (bool value) {
                    discountSettings.setDiscountEnabled(value);
                    showCustomPopup(
                      context: context,
                      title:
                          value ? "Diskon Diaktifkan" : "Diskon Dinonaktifkan",
                      message:
                          value ? "Diskon diaktifkan" : "Diskon dinonaktifkan",
                      confirmText: "OK",
                      duration: 3, // Auto-close dalam 5 detik
                      icon: value
                          ? Icons.check_circle
                          : Icons.block, // Ikon centang
                      iconColor:
                          value ? Colors.green : Colors.red, // Warna hijau
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Input persentase diskon maksimal
                TextFormField(
                  controller: _maxDiscountController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan nilai diskon maksimal (0-100%)',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: discountSettings.isDiscountEnabled,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: discountSettings.isDiscountEnabled
                      ? () {
                          // Simpan pengaturan diskon
                          try {
                            double maxDiscount =
                                double.parse(_maxDiscountController.text);
                            if (maxDiscount < 0 || maxDiscount > 100) {
                              // throw Exception('Nilai harus antara 0-100');
                              showCustomPopup(
                                context: context,
                                title: "Error",
                                message: "Nilai harus antara 0-100",
                                confirmText: "OK",
                                // duration: 5,
                                icon: Icons.error,
                                iconColor: Colors.red,
                              );
                            } else {
                              discountSettings
                                  .setMaxDiscountPercentage(maxDiscount);
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(content: Text('Pengaturan Diskon Disimpan')),
                              // );
                              showCustomPopup(
                                context: context,
                                title: "Pengaturan Diskon Disimpan",
                                message: "Pengaturan diskon disimpan",
                                confirmText: "OK",
                                duration: 5, // Auto-close dalam 5 detik
                                icon: Icons.check_circle, // Ikon centang
                                iconColor: Colors.green, // Warna hijau
                              );
                            }
                          } catch (e) {
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text('Nilai tidak valid: $e')),
                            // );
                            showCustomPopup(
                              context: context,
                              title: "Error",
                              message: "Nilai tidak valid",
                              confirmText: "OK",
                              // duration: 5,
                              icon: Icons.error,
                              iconColor: Colors.red, // Warna hijau
                            );
                          }
                        }
                      : null,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

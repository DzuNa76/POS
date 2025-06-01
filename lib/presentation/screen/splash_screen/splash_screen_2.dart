import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/presentation/screen/setting_desktop_screen/setting_desktop_screen.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/action/mode_of_payment_action/mode_of_payment_action.dart';
import 'package:pos/core/providers/mode_of_payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({Key? key}) : super(key: key);

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi untuk transisi elemen-elemen UI
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    if (ConfigService.isUsingOutlet) {
      checkOutlet();
    } else {
      _fetchModeOfPayment();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void checkOutlet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedOutlet = prefs.getString('selected_outlet');
    if (selectedOutlet != null) {
      // Outlet is already selected, proceed with normal flow
      _fetchModeOfPayment();
    } else {
      // Show dialog when outlet is empty
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Perhatian'),
            content: Text(
                'Outlet belum dipilih. Silakan pilih outlet terlebih dahulu.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Redirect to SettingsPage
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SettingsPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _fetchModeOfPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final provider =
          Provider.of<ModeOfPaymentProvider>(context, listen: false);
      final payment = await ModeOfPaymentAction.getModeOfPayment(1000, 0, '');
      final warehouse = await ModeOfPaymentAction.getWarehouseName();

      final posProfile = await ModeOfPaymentAction.getPosProfile();
      final companyName = posProfile['company'] ?? '';
      final costCenter = posProfile['write_off_cost_center'] ?? '';
      final companyAddress = posProfile['company_address'] ?? '';
      final dataAddress =
          await ModeOfPaymentAction.getCompanyAddress(companyAddress);

      final outletAddress =
          "${dataAddress['address_line1']}, ${dataAddress['address_line2']}, ${dataAddress['county']}, ${dataAddress['city']}, ${dataAddress['state']}, ${dataAddress['pincode']}";
      final outletPhone = dataAddress['phone'];

      print(dataAddress);

      await provider.saveModeOfPayments(payment);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('warehouse_name', warehouse);
      await prefs.setString('company_name', companyName);
      await prefs.setString('cost_center', costCenter);
      await prefs.setString('outlet_address', outletAddress ?? '');
      await prefs.setString('outlet_phone', outletPhone ?? '');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/kasir');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = _parseErrorMessage(e);
      });
    }
  }

  String _parseErrorMessage(dynamic error) {
    // Customize error messages based on different types of exceptions
    if (error.toString().contains('No internet')) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    } else if (error.toString().contains('timeout')) {
      return 'Waktu koneksi habis. Silakan coba lagi.';
    } else if (error.toString().contains('connection')) {
      return 'Gagal terhubung ke server. Periksa koneksi Anda.';
    }
    return 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dengan desain elegan
                  Image.asset(
                    ConfigService.logo,
                    width: 250,
                  ),

                  const SizedBox(height: 40),

                  // Tampilan status loading atau error
                  _isLoading ? _buildLoadingState() : _buildErrorState(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading spinner yang elegan
        SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Memuat data...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        // Icon error yang lebih elegan
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade50,
          ),
          child: Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade800,
            size: 36,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Gagal Memuat Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 16),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 32),
        // Tombol coba lagi yang elegan
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _fetchModeOfPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 12),
                Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

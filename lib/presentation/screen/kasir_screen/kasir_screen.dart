import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/presentation/screen/screen.dart';

class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  // Konstanta untuk threshold mobile
  static const double mobileWidthThreshold = 900;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Logika deteksi platform dan ukuran layar
    if (kIsWeb) {
      // Pada Web, gunakan ukuran layar untuk menentukan desktop/mobile
      return screenWidth < mobileWidthThreshold
          ? const KasirScreenMobile()
          : const KasirScreenDesktop();
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Pada Android/iOS, gunakan ukuran layar untuk menentukan
      return screenWidth < mobileWidthThreshold
          ? const KasirScreenMobile()
          : const KasirScreenDesktop();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Pada platform desktop asli, tetap desktop
      return const KasirScreenDesktop();
    } else {
      // Platform lain fallback ke mobile
      return const KasirScreenMobile();
    }
  }
}

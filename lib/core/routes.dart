import 'package:flutter/material.dart';
import 'package:pos/presentation/screen/history_screen/sales_history_page.dart';
import 'package:pos/presentation/screen/payment_screen/receipt_screen.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:pos/presentation/screen/riwayat_screen/riwayat_screen.dart';
import 'package:pos/presentation/screen/splash_screen/splash_screen_2.dart';
import 'package:pos/presentation/screen/test_screen/test_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String splash2 = '/splash';
  static const String login = '/login';
  static const String kasir = '/kasir';
  static const String profile = '/profile';
  static const String home = '/home';
  static const String setting = '/setting';
  static const String riwayat = '/riwayat';
  static const String history = '/history';
  static const String test = '/test';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case splash2:
        return MaterialPageRoute(builder: (_) => const SplashScreen2());
      case kasir:
        return MaterialPageRoute(builder: (_) => const KasirScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case setting:
        return MaterialPageRoute(builder: (_) => const SettingScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case riwayat:
        return MaterialPageRoute(builder: (_) => const RiwayatScreen());
      case history:
        return MaterialPageRoute(builder: (_) => const SalesHistoryPage());
      case test:
        return MaterialPageRoute(builder: (_) => TestScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

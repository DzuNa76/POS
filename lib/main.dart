import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/core/utils/theme.dart';
import 'package:pos/core/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos/data/api/api_service.dart';
import 'package:pos/data/api/dio_client.dart';
import 'package:pos/data/database/database_page_helper.dart';
import 'package:pos/data/repositories/item_repository.dart';
import 'package:pos/core/providers/discount_provider.dart';
import 'package:pos/core/providers/mode_of_payment.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/core/providers/user_provider.dart';
import 'package:pos/core/providers/voucher_provider.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/auth_provider.dart';
import 'package:pos/core/providers/app_state.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.load();

  // await windowManager.ensureInitialized();

  // // Konfigurasi window untuk full screen
  // WindowOptions windowOptions = const WindowOptions(
  //   fullScreen: true,
  //   center: true,
  //   backgroundColor: Colors.transparent,
  //   skipTaskbar: false,
  // );

  // await windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.setFullScreen(true);
  // });
  await dotenv.load(fileName: ".env");

  if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dioClient = DioClient(); // Inisialisasi DioClient
  final apiService = ApiService(dioClient); // Berikan DioClient ke ApiService
  final dbHelper = DatabasePageHelper.instance;

  final authProvider = AuthProvider();
  await authProvider.loadToken(); // Load token sebelum runApp

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ModeOfPaymentProvider()),
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<ItemRepository>(
          create: (_) => ItemRepository(
            apiService, // Instance ApiService yang sudah dibuat
            DatabasePageHelper.instance, // Instance DatabasePageHelper
          ),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            ItemRepository(apiService, dbHelper),
          ),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DiscountSettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return MaterialApp(
                home:
                    Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.generateRoute,
            );
          },
        );
      },
    );
  }
}

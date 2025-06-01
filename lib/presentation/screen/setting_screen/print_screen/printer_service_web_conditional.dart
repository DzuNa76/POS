// lib/presentation/screen/setting_screen/printer_service_web_conditional.dart
// file conditional export
export 'web_printer_screen_stub.dart'
if (dart.library.html) 'printer_service_web.dart';

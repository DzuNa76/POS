import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:print_usb/model/usb_device.dart';

class PrintState {
  // bluetooth printer yang sudah terhubung
  static BluetoothDevice? connectedPrinter;

  //usb yg terhubung
  static UsbDevice? connectedUsbPrinter;

  // misalnya: '58mm', '72mm', atau '80mm'
  static String? selectedPaperSize;
}

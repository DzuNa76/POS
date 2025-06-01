import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class BluetoothPrinter {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  FlutterBluePlus flutterBlue = FlutterBluePlus();

  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    await Future.delayed(const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.contains(result.device)) {
          devices.add(result.device);
        }
      }
    });

    return devices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _device = device;
    await _device!.connect();
    print('Connected to ${_device!.name}');

    List<BluetoothService> services = await _device!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          _characteristic = characteristic;
          break;
        }
      }
    }
  }

  Future<void> printReceipt() async {
    if (_device == null || _characteristic == null) {
      print('Printer not connected');
      return;
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text('Hello, this is a test print.',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.feed(2);
    bytes += generator.cut();

    await _characteristic!.write(bytes);
    print('Printed successfully');
  }

  Future<void> disconnectPrinter() async {
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
      _characteristic = null;
      print('Printer disconnected');
    }
  }
}

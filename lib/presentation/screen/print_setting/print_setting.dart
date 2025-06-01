import 'package:flutter/material.dart';
import 'package:pos/modules/print.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  _PrinterSettingsPageState createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final BluetoothPrinter _bluetoothPrinter = BluetoothPrinter();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isLoading = false;
  bool _isConnected = false;

  String? _selectedPrinterMode;
  String? _selectedPaperSize;

  final List<String> _printerModes = ['Mode 1', 'Mode 2', 'Mode 3'];
  final List<String> _paperSizes = ['58mm', '80mm', '100mm'];

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
  }

  Future<void> _savePrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_mode', _selectedPrinterMode ?? '');
    await prefs.setString('paper_size', _selectedPaperSize ?? '');
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterMode = prefs.getString('printer_mode') ?? _printerModes[0];
      _selectedPaperSize = prefs.getString('paper_size') ?? _paperSizes[0];
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isLoading = true;
      _devices = [];
    });

    try {
      final devices = await _bluetoothPrinter.scanDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning devices: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectPrinter(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bluetoothPrinter.connectToDevice(device);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_address', device.id.id);
      await prefs.setString('printer_name', device.name);

      setState(() {
        _selectedDevice = device;
        _isConnected = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer connected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to printer: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bluetoothPrinter.disconnectPrinter();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('printer_address');
      await prefs.remove('printer_name');

      setState(() {
        _selectedDevice = null;
        _isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer disconnected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error disconnecting printer: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPrint() async {
    try {
      await _bluetoothPrinter.printReceipt();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isConnected) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Connected Printer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${_selectedDevice?.name ?? "Unknown"}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _testPrint,
                        child: const Text('Test Print'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _disconnectPrinter,
                        child: const Text('Disconnect Printer'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _scanDevices,
                child: const Text('Scan for Printers'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

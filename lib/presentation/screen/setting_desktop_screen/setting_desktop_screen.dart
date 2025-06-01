import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/data/api/mode_of_payment_data.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:pos/presentation/screen/splash_screen/splash_screen_2.dart';
import 'package:pos/presentation/widgets/sidebar_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Section options
  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'POS Settings',
      'icon': Icons.point_of_sale,
    },
    {
      'title': 'Setting Printer',
      'icon': Icons.print,
    },
    {
      'title': 'Setting Printer Resi',
      'icon': Icons.print,
    },
    {
      'title': 'Versi Aplikasi',
      'icon': Icons.info_outline,
    },
  ];

  int _selectedSectionIndex = 0;
  final TextEditingController _printerIpController = TextEditingController();
  final TextEditingController _printerIpResiController =
      TextEditingController();
  String _savedPrinterIp = '';
  String _savedPrinterIpResi = '';
  bool _isSaving = false;
  List<String> _printers = [];
  List<String> _printersResi = [];
  String? _selectedPrinter;
  String? _selectedPrinterResi;
  String _printerMode = 'POS';
  String _printerModeResi = 'Generic';
  String _paperSize = '80mm';
  String _paperSizeResi = 'A4';
  String _appVersion = '';
  bool _allowStock = false;
  bool _discountPerItem = false;
  bool _isGridView = true;
  List<Map<String, dynamic>> _outlets = [];
  String? _selectedOutlet;

  @override
  void initState() {
    super.initState();
    if (ConfigService.isUsingOutlet) {
      _fetchPOSProfile();
    }
    _getAppVersion();
    _loadSavedPrinterIp();
    _loadSavedPrinterIpResi();
    _loadPosSettings();
    if (mounted) {
      setState(() {
        _selectedPrinter = '';
        _selectedPrinterResi = '';
      });
    }
  }

  Future<void> _fetchPOSProfile() async {
    final response = await getAllModeOfPayment();

    try {
      if (response != null && response['data'] != null) {
        setState(() {
          _outlets = List<Map<String, dynamic>>.from(response['data']);
        });

        // Load selected outlet from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final savedOutlet = prefs.getString('selected_outlet');
        if (savedOutlet != null &&
            _outlets.any((outlet) => outlet['name'] == savedOutlet)) {
          setState(() {
            _selectedOutlet = savedOutlet;
          });
        } else if (_outlets.isNotEmpty) {
          setState(() {
            _selectedOutlet = _outlets[0]['name'];
          });
        }
      }
    } catch (e) {
      print('Error parsing outlet data: $e');
    }
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadPosSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allowStock = prefs.getBool('allow_stock') ?? false;
      _discountPerItem = prefs.getBool('discount_per_item') ?? false;
      _isGridView = prefs.getBool('view_mode') ?? true;
    });
  }

  Future<void> _savePosSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('allow_stock', _allowStock);
      await prefs.setBool('discount_per_item', _discountPerItem);
      await prefs.setBool('view_mode', _isGridView);
      if (ConfigService.isUsingOutlet) {
        await prefs.setString('selected_outlet', _selectedOutlet ?? '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan POS berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      if (ConfigService.isUsingOutlet) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SplashScreen2(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _fetchPrinters(String ip) async {
    try {
      print(ip);
      final response = await http.get(Uri.parse('http://$ip:5577/getPrinters'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _printers = List<String>.from(
                data['data']['printer'].map((printer) => printer['name']));

            print(_printers);
          });
        }
      } else {
        throw Exception('Failed to load printers');
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching printers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchPrintersResi(String ip) async {
    try {
      print(ip);
      final response = await http
          .get(Uri.parse('http://$ip:5577/getPrinters'))
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _printersResi = List<String>.from(
                data['data']['printer'].map((printer) => printer['name']));

            print(_printersResi);
          });
        }
      } else {
        throw Exception('Failed to load printers');
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching printers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSavedPrinterIp() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPrinterIp = prefs.getString('printer_settings') ?? '';

    log(_savedPrinterIp);

    setState(() {
      if (_savedPrinterIp.isNotEmpty) {
        final data = json.decode(_savedPrinterIp);
        _printerIpController.text = data['printer_ip'];
        _selectedPrinter = data['printer_name'];
        _printerMode = data['printer_mode'];
        _paperSize = data['paper_size'];
      }
      // _printerIpController.text = _savedPrinterIp;
    });
  }

  Future<void> _loadSavedPrinterIpResi() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPrinterIpResi = prefs.getString('printer_resi_settings') ?? '';

    setState(() {
      if (_savedPrinterIpResi.isNotEmpty) {
        final data = json.decode(_savedPrinterIpResi);
        _printerIpResiController.text = data['printer_ip'];
        _selectedPrinterResi = data['printer_name'];
        _printerModeResi = data['printer_mode'];
        _paperSizeResi = data['paper_size'];
      }
      // _printerIpController.text = _savedPrinterIp;
    });
  }

  Future<void> _savePrinterIp() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final jsonString = json.encode({
        'printer_ip': _printerIpController.text.isEmpty
            ? '127.0.0.1'
            : _printerIpController.text,
        'printer_name': _selectedPrinter,
        'printer_mode': _printerMode,
        'paper_size': _paperSize,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_settings', jsonString);

      setState(() {
        _savedPrinterIp = _printerIpController.text.isEmpty
            ? '127.0.0.1'
            : _printerIpController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat IP printer berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan alamat IP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _savePrinterIpResi() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final jsonString = json.encode({
        'printer_ip': _printerIpResiController.text.isEmpty
            ? '127.0.0.1'
            : _printerIpResiController.text,
        'printer_name': _selectedPrinterResi,
        'printer_mode': _printerModeResi,
        'paper_size': _paperSizeResi,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_resi_settings', jsonString);

      setState(() {
        _savedPrinterIpResi = _printerIpResiController.text.isEmpty
            ? '127.0.0.1'
            : _printerIpResiController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat IP printer berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan alamat IP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _goToKasirPage() async {
    if (ConfigService.isUsingOutlet) {
      final prefs = await SharedPreferences.getInstance();
      final outlet = prefs.getString('selected_outlet');

      if (outlet != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                KasirScreenDesktop(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an outlet first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              KasirScreenDesktop(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Setting',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF533F77), // Main color
                Color(0xFF6A5193), // Lighter variation
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        leadingWidth: MediaQuery.of(context).size.width * 0.4,
        actions: [
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const VerticalDivider(
              thickness: 1,
              color: Color.fromARGB(64, 255, 255, 255),
            ),
          ),
          _buildMenuButton(
            icon: Icons.close,
            label: "",
            onPressed: () => _goToKasirPage(),
            borderColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),
        ],
        elevation: 8,
      ),
      drawer: const SidebarMenu(),
      body: Row(
        children: [
          // Left column - Section options
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(1, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF5F5F5),
                  child: const Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF533F77)),
                      SizedBox(width: 10),
                      Text(
                        'Menu Pengaturan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF533F77),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final bool isSelected = _selectedSectionIndex == index;

                      return Material(
                        color: isSelected
                            ? const Color(
                                0xFFF0EAFB) // Light purple when selected
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSectionIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                left: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF533F77)
                                      : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  section['icon'],
                                  color: isSelected
                                      ? const Color(0xFF533F77)
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  section['title'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF533F77)
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right column - Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade50,
              child: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSectionIndex) {
      case 0:
        return _buildPosSettings();
      case 1:
        return _buildPrinterSettings();
      case 2:
        return _buildPrinterResiSettings();
      case 3:
        return _buildAppVersionInfo();
      default:
        return const Center(child: Text('Pilih section dari menu di samping.'));
    }
  }

  Widget _buildPosSettings() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POS Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF533F77),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pengaturan tambahan untuk sistem Point of Sale',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'General POS Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF533F77),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (ConfigService.isUsingOutlet)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Outlet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih outlet yang akan digunakan untuk transaksi',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedOutlet,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              hintText: 'Pilih outlet',
                            ),
                            items: _outlets.map((outlet) {
                              return DropdownMenuItem<String>(
                                value: outlet['name'],
                                child: Text(outlet['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedOutlet = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tampilan Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Tampilan Grid'),
                                  value: true,
                                  groupValue: _isGridView,
                                  onChanged: (value) {
                                    setState(() {
                                      _isGridView = value ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF533F77),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Tampilan List'),
                                  value: false,
                                  groupValue: _isGridView,
                                  onChanged: (value) {
                                    setState(() {
                                      _isGridView = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF533F77),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _allowStock,
                    onChanged: (value) {
                      setState(() {
                        _allowStock = value ?? false;
                      });
                    },
                    title: const Text(
                      'Jual Item Stok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Aktifkan bila anda menjual item dengan stok',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    activeColor: const Color(0xFF533F77),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    tileColor: Colors.grey.shade50,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _discountPerItem,
                    onChanged: (value) {
                      setState(() {
                        _discountPerItem = value ?? false;
                      });
                    },
                    title: const Text(
                      'Discount Per Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Aktifkan bila anda ingin menerapkan discount Per Item',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    activeColor: const Color(0xFF533F77),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    tileColor: Colors.grey.shade50,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _savePosSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                          label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF533F77),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Setting Printer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF533F77),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Atur alamat IP printer yang akan digunakan untuk mencetak struk',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat IP Printer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _printerIpController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 192.168.1.100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.print,
                      color: Color(0xFF533F77),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _fetchPrinters(_printerIpController.text.isEmpty
                        ? '127.0.0.1'
                        : _printerIpController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF533F77),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Check Printer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_printers.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _printers.contains(_selectedPrinter)
                        ? _selectedPrinter
                        : null,
                    hint: const Text('Pilih Printer'),
                    items: _printers.toSet().map((printer) {
                      return DropdownMenuItem<String>(
                        value: printer,
                        child: Text(printer),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrinter = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _printerMode,
                    items: const [
                      DropdownMenuItem(value: 'POS', child: Text('POS')),
                      DropdownMenuItem(
                          value: 'Generic', child: Text('Generic')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _printerMode = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Mode Printer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _paperSize,
                    items: const [
                      DropdownMenuItem(value: '55mm', child: Text('55mm')),
                      DropdownMenuItem(value: '57mm', child: Text('57mm')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paperSize = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Ukuran Kertas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _savePrinterIp,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                          label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF533F77),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_savedPrinterIp.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'IP Printer saat ini: ${_printerIpController.text.isEmpty ? '127.0.0.1' : _printerIpController.text}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterResiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Setting Printer Resi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF533F77),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Atur alamat IP printer yang akan digunakan untuk mencetak Resi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat IP Printer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _printerIpResiController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 192.168.1.100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.print,
                      color: Color(0xFF533F77),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _fetchPrintersResi(_printerIpResiController.text.isEmpty
                        ? '127.0.0.1'
                        : _printerIpResiController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF533F77),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Check Printer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_printersResi.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _printersResi.contains(_selectedPrinterResi)
                        ? _selectedPrinterResi
                        : null,
                    hint: const Text('Pilih Printer'),
                    items: _printersResi.toSet().map((printer) {
                      return DropdownMenuItem<String>(
                        value: printer,
                        child: Text(printer),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPrinterResi = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _printerModeResi,
                    items: const [
                      DropdownMenuItem(
                          value: 'Generic', child: Text('Generic')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _printerModeResi = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Mode Printer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _paperSizeResi,
                    items: const [
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paperSizeResi = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Ukuran Kertas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _savePrinterIpResi,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                          label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF533F77),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_savedPrinterIpResi.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'IP Printer saat ini: ${_printerIpResiController.text.isEmpty ? '127.0.0.1' : _printerIpResiController.text}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Versi Aplikasi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF533F77),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Informasi tentang aplikasi dan versi saat ini',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF0EAFB),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    size: 48,
                    color: Color(0xFF533F77),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thunder POS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF533F77),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Versi $_appVersion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF533F77),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sistem Point of Sale untuk manajemen penjualan dan inventori. Aplikasi ini dirancang untuk memudahkan proses transaksi, pelacakan stok, dan pelaporan penjualan dengan antarmuka yang intuitif dan modern.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // _buildInfoItem(
                    //   icon: Icons.calendar_today,
                    //   title: 'Tanggal Rilis',
                    //   value: '01 April 2025',
                    // ),
                    // const SizedBox(width: 40),
                    _buildInfoItem(
                      icon: Icons.code,
                      title: 'Build Number',
                      value: _appVersion,
                    ),
                    // const SizedBox(width: 40),
                    // _buildInfoItem(
                    //   icon: Icons.update,
                    //   title: 'Last Update',
                    //   value: '07 April 2025',
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF533F77),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    Color? borderColor,
    bool clickable = true,
  }) {
    final bool hasLabel = label.trim().isNotEmpty;
    final bool isClickable = clickable && onPressed != null;

    // Default colors if not provided
    final Color _backgroundColor =
        backgroundColor ?? const Color(0xFF533F77).withOpacity(0.3);
    final Color _textColor = textColor ?? Colors.white;
    final Color _iconColor = iconColor ?? Colors.white;
    final Color _borderColor = borderColor ?? Colors.white30;

    // Common widget properties
    final borderRadius = BorderRadius.circular(10);

    // Non-clickable widget
    if (!isClickable) {
      return Container(
        padding: hasLabel
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: _borderColor),
        ),
        child: hasLabel
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: _iconColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            : Icon(icon, color: _iconColor, size: 18),
      );
    }

    // Clickable widget
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: _borderColor),
      ),
      child: hasLabel
          ? TextButton.icon(
              icon: Icon(icon, color: _iconColor, size: 18),
              label: Text(
                label,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(10, 38),
                backgroundColor: _backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                ),
                elevation: 0,
              ),
              onPressed: onPressed,
            )
          : TextButton(
              child: Icon(icon, color: _iconColor, size: 26),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(2),
                minimumSize: const Size(10, 38),
                backgroundColor: _backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                ),
              ),
              onPressed: onPressed,
            ),
    );
  }
}

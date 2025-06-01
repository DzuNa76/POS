import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/action/voucher/voucher_action.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/core/providers/mode_of_payment.dart';
import 'package:pos/core/providers/preference_helper.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/core/theme/app_colors.dart';
import 'package:pos/core/utils/config.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/data/models/voucher/voucher.dart';
import 'package:pos/presentation/screen/history_screen/sales_history_page.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/modal_check_stock.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/modal_input_order.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/modal_kasbon.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/modal_save_bill.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/product.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/modal_input_customer.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/discount_widget.dart';
import 'package:pos/presentation/screen/setting_desktop_screen/setting_desktop_screen.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class KasirScreenDesktop extends StatefulWidget {
  const KasirScreenDesktop({super.key});

  @override
  _KasirScreenDesktopState createState() => _KasirScreenDesktopState();
}

class _KasirScreenDesktopState extends State<KasirScreenDesktop> {
  // Constants
  static const _primaryColor = AppColors.primary;
  static const _dividerColor = Color.fromARGB(255, 192, 191, 191);

  // State Variables
  final List<String> _paymentMethods = [""];
  bool _isSyncing = false;
  bool _isGridView = true;
  Customer? _selectedCustomer;
  String? _selectedPaymentMethod = "TUNAI";
  bool isLoading = false;
  String channel = "OFFLINE";
  String user = "";
  bool _allowStock = false;
  List<VoucherModel> voucher = [];
  String sid = '';
  String discountDatas = '';
  String _outletName = '';

  // Controllers
  final _cashAmountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Formatters
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Cache for SharedPreferences
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _prefs = await SharedPreferences.getInstance();

    // Load data sequentially
    _loadViewMode();
    _handleLoadCustomer();
    _loadUser();
    _handleCheckPosSettings();
    await _loadVouchers();
    _loadOutletName();

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadModeOfPayment();
    _handleLoadCustomer();
    _loadUser();
    _handleCheckPosSettings();
    _loadOutletName();
  }

  Future<void> _loadViewMode() async {
    final isGrid = _prefs?.getBool('view_mode') ?? true;
    if (mounted) {
      setState(() => _isGridView = isGrid);
    }
  }

  Future<void> _handleLoadCustomer() async {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);
    if (customerProvider.customer != null) {
      setState(() => _selectedCustomer = customerProvider.customer);
    }
  }

  Future<void> _loadUser() async {
    String? fullName = _prefs?.getString('full_name');
    if (mounted) {
      setState(() => user = fullName ?? 'Guest');
    }
  }

  Future<void> _handleCheckPosSettings() async {
    final allowStock = _prefs?.getBool('allow_stock') ?? false;
    if (mounted) {
      setState(() => _allowStock = allowStock);
    }
  }

  Future<void> _loadOutletName() async {
    final outletName = _prefs?.getString('selected_outlet') ?? '';
    if (mounted) {
      setState(() => _outletName = '- $outletName');
    }
  }

  void _loadModeOfPayment() {
    final provider = Provider.of<ModeOfPaymentProvider>(context, listen: false);
    final payments = provider.modeOfPayments;

    if (mounted) {
      setState(() {
        _paymentMethods.clear();
        _paymentMethods.addAll(payments.isNotEmpty
            ? payments.map((payment) => payment.modeOfPayment).toList()
            : ["TUNAI"]);
        _selectedPaymentMethod =
            _paymentMethods.contains(_selectedPaymentMethod)
                ? _selectedPaymentMethod
                : _paymentMethods.first;
      });
    }
  }

  Future<void> _loadVouchers() async {
    final sids = _prefs?.getString('sid') ?? '';
    final vouchers = await VoucherAction.getVouchers(200, 0, '');
    final voucherDatas = _prefs?.getString('voucher_datas') ?? '';
    if (mounted) {
      setState(() {
        voucher = vouchers;
        sid = sids;
        discountDatas = voucherDatas;
      });
    }
  }

  @override
  void dispose() {
    _cashAmountController.dispose();
    _referenceController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSimpanKeranjang() async {
    final prefs = await SharedPreferences.getInstance();
    final voucher = prefs.getBool('voucher_used') ?? false;
    if (voucher == true) {
      _showSnackBar(
          'Terdapat Voucher yang terpasang, hapus voucher terlebih dahulu',
          isError: true);
      return;
    }
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keranjang masih kosong!')),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih pelanggan terlebih dahulu!')),
      );
      return;
    } else {
      await cartProvider.saveCartToLocalStorage(_selectedCustomer!);
      cartProvider.clearCart();

      cartProvider.loadPesanan().then((test) {
        for (var a in test) {
          cartProvider.deletePesananById(a['invoiceNumber']);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keranjang berhasil disimpan!')),
      );
    }
  }

  void _handleBuatPesanan() async {
    final prefs = await SharedPreferences.getInstance();
    final voucher = prefs.getBool('voucher_used') ?? false;
    if (voucher == true) {
      _showSnackBar(
          'Terdapat Voucher yang terpasang, hapus voucher terlebih dahulu',
          isError: true);
      return;
    }
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    if (cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keranjang Kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (customerProvider.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer Kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, dynamic>> dataItem = cartProvider.cartItems.map((item) {
      return {
        "id": item.id,
        "item_code": item.itemCode,
        "item_name": item.itemName,
        "description": item.description,
        "uom": item.uom,
        "conversion_factor": item.conversionFactor,
        "qty": item.qty,
        "rate": item.rate,
        "amount": item.amount,
        "base_rate": item.baseRate,
        "base_amount": item.baseAmount,
        "price_list_rate": item.priceListRate,
        "const_center": item.costCenter,
        "discount_value": item.discountValue,
        "is_discount_percent": item.isDiscountPercent
      };
    }).toList();

    try {
      setState(() {
        isLoading = true;
      });

      double totalPrice = dataItem.fold(0.0, (sum, item) {
        return sum + ((item['price_list_rate'] ?? 0) * (item['qty'] ?? 0));
      });

      double billedAmount = dataItem.fold(0.0, (sum, item) {
        return sum + ((item['rate'] ?? 0) * (item['qty'] ?? 0));
      });
      var response = await SalesDataActions.postSalesInvoice(
          customerCode: _selectedCustomer!.code.toString(),
          customerName: _selectedCustomer!.name.toString(),
          dataItems: dataItem!.map((item) {
            final discount = item['price_list_rate'] - item['amount'];
            return {
              "idx": 1,
              "item_code": item['item_code'],
              "item_name": item['item_name'],
              "stock_uom": item['uom'],
              "description": item['description'],
              "qty": item['qty'],
              "discount_amount": discount,
              "price_list_rate": item['price_list_rate'],
              "rate": item['amount'],
              "amount": item['amount']
            };
          }).toList(),
          totalPrice: totalPrice,
          billedAmount: billedAmount,
          channel: "OFFLINE");

      if (response['status'] == 'success') {
        print('Order successfully created!');

        cartProvider.clearCart();
        _clearSelectedCustomer();

        cartProvider.loadPesanan().then((test) {
          for (var a in test) {
            cartProvider.deletePesananById(a['invoiceNumber']);
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order successfully created!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        print('Failed to create order: $response');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $response'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('An error occurred: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  // Generalized SnackBar Method
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // TUNAI Payment Calculation
  int? _calculateCashPaymentStatus(double totalPrice) {
    final cashText = _cashAmountController.text;
    if (cashText.isEmpty) return null;

    final cashAmount =
        int.tryParse(cashText.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    return cashAmount < totalPrice
        ? -1
        : cashAmount > totalPrice
            ? cashAmount - totalPrice.toInt()
            : 0;
  }

  void _openSaveBillDialog() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    List<Map<String, dynamic>> savedTransactions =
        await cartProvider.loadCartFromLocalStorage();

    showDialog(
      context: context,
      builder: (context) => CartModal(
        transactions: savedTransactions,
      ),
    );
  }

  void _openPesananDialog() async {
    showDialog(
      context: context,
      builder: (context) => CreateOrderModal(),
    );
  }

  void _checkStock() {
    showDialog(
      context: context,
      builder: (context) => ItemStockModal(),
    );
  }

  void _openKasbonDialog() {
    showDialog(
      context: context,
      builder: (context) => ModalKasbon(),
    );
  }

  // Customer Selection Handler
  void _handleCustomerSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final voucher = prefs.getBool('voucher_used') ?? false;
    print('voucher: $voucher');
    if (voucher == false) {
      final result = await showDialog(
        context: context,
        builder: (context) => const CustomerModal(),
      );

      if (result != null && result is Customer) {
        setState(() => _selectedCustomer = result);
        _showSnackBar('Selected Customer: ${result.name}');
      }
    } else {
      _showSnackBar(
          'Terdapat Voucher yang terpasang, hapus voucher terlebih dahulu',
          isError: true);
      return;
    }
  }

  // Clear Selected Customer
  Future<void> _clearSelectedCustomer() async {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);
    await customerProvider.deleteCustomer();
    final prefs = await SharedPreferences.getInstance();
    final voucher = prefs.getBool('voucher_used') ?? false;
    if (voucher == false) {
      setState(() => _selectedCustomer = null);
      _showSnackBar('Berhasil Clear Customer');

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              KasirScreenDesktop(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      _showSnackBar(
          'Terdapat Voucher yang terpasang, hapus voucher terlebih dahulu',
          isError: true);
    }
  }

  void _openRiwayatDialog() {
    Navigator.pushNamed(context, '/history');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SalesHistoryPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openSettingDialog() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.shade400,
                            Colors.red.shade300,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade200.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF533F77),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Apakah Anda yakin ingin keluar dari aplikasi?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF533F77),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (shouldLogout ?? false) {
      final prefs = await SharedPreferences.getInstance();
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final CustomerProvider customerProvider =
          Provider.of<CustomerProvider>(context, listen: false);

      // Simpan data yang ingin dipertahankan
      final savedTransactions = prefs.getString('saved_transactions');
      final printerSetting = prefs.getString('printer_settings');
      final printerResiSetting = prefs.getString('printer_resi_settings');

      // Hapus semua data
      await prefs.clear();
      cartProvider.clearCart();
      customerProvider.deleteCustomer();

      // Simpan kembali data yang tidak ingin dihapus
      if (savedTransactions != null) {
        await prefs.setString('saved_transactions', savedTransactions);
      }

      if (printerSetting != null) {
        await prefs.setString('printer_settings', printerSetting);
      }

      if (printerResiSetting != null) {
        await prefs.setString('printer_resi_settings', printerResiSetting);
      }

      // Arahkan ke halaman login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  static Map<String, dynamic> discountMaps(String discountData) {
    try {
      // Handle the string as Dart Map representation instead of JSON
      // Remove the curly braces and split by commas
      String processedData = discountData.trim();

      // If the data already looks like valid JSON (starting with {"), just parse it as JSON
      if (processedData.startsWith('{"')) {
        final Map<String, dynamic> discountMap = jsonDecode(processedData);
        return discountMap;
      }

      // Otherwise, handle it as Dart Map representation
      if (processedData.startsWith('{')) {
        processedData = processedData.substring(1);
      }
      if (processedData.endsWith('}')) {
        processedData = processedData.substring(0, processedData.length - 1);
      }

      Map<String, dynamic> discountMap = {};

      // Split the string by key-value pairs
      RegExp regExp = RegExp(r'([^:,]+):\s*([^,]+)(?:,|$)');
      RegExp listRegExp = RegExp(r'([^:,]+):\s*(\[[^\]]+\])(?:,|$)');
      RegExp mapRegExp = RegExp(r'([^:,]+):\s*(\{[^}]+\})(?:,|$)');

      // First extract lists and maps
      Iterable<RegExpMatch> listMatches = listRegExp.allMatches(processedData);
      for (RegExpMatch match in listMatches) {
        String key = match.group(1)?.trim() ?? '';
        String value = match.group(2)?.trim() ?? '';

        if (value.startsWith('[') && value.endsWith(']')) {
          // Process lists
          String listContent = value.substring(1, value.length - 1).trim();
          List<Map<String, dynamic>> itemsList = [];

          // Split by closing braces to separate map items
          List<String> items = [];
          int depth = 0;
          String currentItem = '';

          for (int i = 0; i < listContent.length; i++) {
            if (listContent[i] == '{') {
              depth++;
              currentItem += '{';
            } else if (listContent[i] == '}') {
              depth--;
              currentItem += '}';
              if (depth == 0) {
                items.add(currentItem);
                currentItem = '';
              }
            } else {
              if (depth > 0 || listContent[i].trim().isNotEmpty) {
                currentItem += listContent[i];
              }
            }
          }

          for (String item in items) {
            if (item.trim().isNotEmpty) {
              Map<String, dynamic> itemMap = {};
              String itemContent = item.trim();
              if (itemContent.startsWith('{')) {
                itemContent = itemContent.substring(1);
              }
              if (itemContent.endsWith('}')) {
                itemContent = itemContent.substring(0, itemContent.length - 1);
              }

              RegExp itemRegExp = RegExp(r'([^:,]+):\s*([^,]+)(?:,|$)');
              Iterable<RegExpMatch> itemMatches =
                  itemRegExp.allMatches(itemContent);
              for (RegExpMatch itemMatch in itemMatches) {
                String itemKey = itemMatch.group(1)?.trim() ?? '';
                String itemValue = itemMatch.group(2)?.trim() ?? '';
                itemMap[itemKey] = _parseValue(itemValue);
              }

              itemsList.add(itemMap);
            }
          }

          discountMap[key] = itemsList;
          // Remove the processed part from the string
          processedData = processedData.replaceAll(match.group(0) ?? '', '');
        }
      }

      // Extract nested maps
      Iterable<RegExpMatch> mapMatches = mapRegExp.allMatches(processedData);
      for (RegExpMatch match in mapMatches) {
        String key = match.group(1)?.trim() ?? '';
        String value = match.group(2)?.trim() ?? '';

        if (value.startsWith('{') && value.endsWith('}')) {
          // Process maps
          String mapContent = value.substring(1, value.length - 1).trim();
          Map<String, dynamic> nestedMap = {};

          RegExp nestedRegExp = RegExp(r'([^:,]+):\s*([^,]+)(?:,|$)');
          Iterable<RegExpMatch> nestedMatches =
              nestedRegExp.allMatches(mapContent);
          for (RegExpMatch nestedMatch in nestedMatches) {
            String nestedKey = nestedMatch.group(1)?.trim() ?? '';
            String nestedValue = nestedMatch.group(2)?.trim() ?? '';
            nestedMap[nestedKey] = _parseValue(nestedValue);
          }

          discountMap[key] = nestedMap;
          // Remove the processed part from the string
          processedData = processedData.replaceAll(match.group(0) ?? '', '');
        }
      }

      // Process remaining key-value pairs
      Iterable<RegExpMatch> matches = regExp.allMatches(processedData);
      for (RegExpMatch match in matches) {
        String key = match.group(1)?.trim() ?? '';
        String value = match.group(2)?.trim() ?? '';
        if (key.isNotEmpty) {
          discountMap[key] = _parseValue(value);
        }
      }
      return discountMap;
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final totalPrice = context.watch<CartProvider>().totalPrice;
    final dataDiscount = discountMaps(discountDatas);

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const SidebarMenu(),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildProductSection(),
                VerticalDivider(color: _dividerColor),
                _buildCustomerSection(),
                VerticalDivider(color: _dividerColor),
                _buildPaymentSection(totalPrice, dataDiscount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Kasir $_outletName',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF533F77),
              Color(0xFF6A5193),
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
      leading: _buildLeadingButtons(),
      actions: _buildActionButtons(),
      elevation: 8,
    );
  }

  Widget _buildLeadingButtons() {
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          _buildMenuButton(
            icon: Icons.receipt_outlined,
            label: 'Pesanan',
            onPressed: () => _openPesananDialog(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fontSize: 13,
            iconSize: 18,
          ),
          const SizedBox(width: 8),
          _buildMenuButton(
            icon: Icons.shopping_cart_outlined,
            label: 'Disimpan',
            onPressed: () => _openSaveBillDialog(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fontSize: 13,
            iconSize: 18,
          ),
          const SizedBox(width: 8),
          _buildMoreMenuButton(),
        ],
      ),
    );
  }

  Widget _buildMoreMenuButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF533F77).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_horiz, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            const Text(
              'Menu Lainnya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildMenuItem(
          icon: Icons.history_outlined,
          label: 'Riwayat',
          onTap: () => _openRiwayatDialog(),
        ),
        if (ConfigService.isUsingCheckStock && _allowStock)
          _buildMenuItem(
            icon: Icons.inventory,
            label: 'Cek Stock',
            onTap: () => _checkStock(),
          ),
        if (ConfigService.isUsingKasbon)
          _buildMenuItem(
            icon: Icons.money_outlined,
            label: 'Kasbon',
            onTap: () => _openKasbonDialog(),
          ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuButton(
            icon: Icons.settings_outlined,
            label: '',
            onPressed: () => _openSettingDialog(),
            backgroundColor: Colors.transparent,
            iconColor: Colors.white,
            textColor: Colors.white,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(8),
            iconSize: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const VerticalDivider(
              thickness: 1,
              color: Color.fromARGB(64, 255, 255, 255),
            ),
          ),
          _buildMenuButton(
            icon: Icons.person,
            label: user,
            onPressed: () => {},
            clickable: false,
            borderColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            iconColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fontSize: 13,
            iconSize: 18,
          ),
          _buildMenuButton(
            icon: Icons.power_settings_new_outlined,
            label: "",
            onPressed: () => _handleLogout(),
            backgroundColor: Colors.red,
            iconColor: Colors.white,
            textColor: Colors.white,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(8),
            iconSize: 20,
          ),
          const SizedBox(width: 8),
        ],
      ),
    ];
  }

  Widget _buildProductSection() {
    return Expanded(
      flex: 2,
      child: Container(
        color: Colors.white.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            children: [
              Expanded(
                child: ProductCartScreen(
                  searchFocusNode: _searchFocusNode,
                  isGridView: _isGridView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Expanded(
      flex: 1,
      child: Container(
        color: Colors.white.withOpacity(0.4),
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _selectedCustomer == null
                  ? _buildCustomerInputButton()
                  : _buildCustomerDetails(),
              const SizedBox(height: 8),
              if (ConfigService.isUsingPaymentChannel)
                OrderOptionsWidget(
                  useDropdown: true,
                  item: const ['OFFLINE', 'ONLINE'],
                  dropDownTitle: "Jalur Penjualan",
                  onChanged: (selectedValue) {
                    if (mounted) {
                      setState(() => channel = selectedValue);
                    }
                  },
                ),
              const SizedBox(height: 8),
              Expanded(
                child: DiscountVoucherWidget(
                  onDiscountApplied: (discount) {},
                  onVoucherApplied: (datas) {
                    setState(() => discountDatas = datas);
                  },
                  voucher: voucher,
                  sid: sid,
                  isApplyButtonEnabled: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keranjang',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF533F77),
                ),
              ),
              const SizedBox(height: 16),
              _simpanKeranjang(),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection(
      double totalPrice, Map<String, dynamic> dataDiscount) {
    return Expanded(
      flex: 1,
      child: Container(
        color: Colors.white.withOpacity(0.4),
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalBillRow(dataDiscount, totalPrice),
              Divider(color: _dividerColor),
              _buildDiscountInfo(discountDatas),
              _buildPaymentHeader(totalPrice),
              Divider(color: _dividerColor),
              const SizedBox(height: 16),
              _buildPaymentMethodDropdown(),
              const SizedBox(height: 16),
              if (_selectedPaymentMethod != null) ...[
                if (_selectedPaymentMethod == 'TUNAI')
                  _buildCashAmountInput(totalPrice),
                if (_selectedPaymentMethod != 'TUNAI') _buildReferenceInput(),
              ],
              const SizedBox(height: 16),
              _buildCashPaymentStatus(totalPrice),
              const SizedBox(height: 12),
              const Spacer(),
              if (_selectedPaymentMethod != 'TUNAI' ||
                  (_cashAmountController.text.isNotEmpty &&
                      _calculateCashPaymentStatus(totalPrice) != -1))
                VoucherAndTotalWidget(
                  cashAmount: _selectedPaymentMethod == 'TUNAI'
                      ? int.parse(_cashAmountController.text
                          .replaceAll(RegExp(r'[^\d]'), ''))
                      : totalPrice.toInt(),
                  paymentMethod: _selectedPaymentMethod,
                  referensi: _referenceController.text,
                  channel: channel,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalBillRow(
      Map<String, dynamic> dataDiscount, double totalPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Total Tagihan ",
              style: TextStyle(
                fontSize: 14,
                color: _primaryColor,
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatter.format(
                dataDiscount['total_before_discount'] ?? totalPrice,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Customer Input Button
  Widget _buildCustomerInputButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        minHeight: 200, // Set a minimum height
        maxHeight: 200, // Set a maximum height
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.person_add_alt_1_outlined,
              size: 40,
              color: _primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Click Button below to add customer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _handleCustomerSelection,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        minHeight: 200, // Same minimum height as input button
        maxHeight: 200, // Same maximum height as input button
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                Icon(
                  Icons.person_pin,
                  color: _primaryColor.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.person, "${_selectedCustomer!.name}"),
            _buildDetailRow(Icons.phone, "${_selectedCustomer!.phone}"),
            _buildDetailRow(Icons.location_on, "${_selectedCustomer!.address}"),
            const SizedBox(height: 12),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearSelectedCustomer,
                    icon: const Icon(
                      Icons.clear,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleCustomerSelection,
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
    );
  }

  // Helper method to create consistent detail rows
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: _primaryColor.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Payment Header
  Widget _buildPaymentHeader(double totalPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text(
            "Grand Total",
            style: TextStyle(
              fontSize: 14,
              color: _primaryColor,
            ),
          )
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatter.format(totalPrice),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Payment Method Dropdown
  Widget _buildPaymentMethodDropdown() {
    return CustomDropdown<String>.search(
      searchHintText: "Cari Metode Pembayaran",
      closedHeaderPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      hintText: "Pilih Metode Pembayaran",
      items: _paymentMethods,
      initialItem: _selectedPaymentMethod,
      decoration: CustomDropdownDecoration(
          closedBorder: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            top: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
            right: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          closedFillColor: Colors.grey.shade100),
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value;
          _cashAmountController.clear();
          _referenceController.clear();
        });
      },
    );
  }

  // TUNAI Amount Input
  Widget _buildCashAmountInput(double totalPrice) {
    return TextFormField(
      controller: _cashAmountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      onChanged: (value) {
        if (value.isNotEmpty) {
          String formattedValue =
              _formatter.format(int.parse(value.replaceAll(RegExp(r'\D'), '')));
          _cashAmountController.value = TextEditingValue(
            text: formattedValue,
            selection: TextSelection.collapsed(offset: formattedValue.length),
          );
        }
        setState(() {}); // Force rebuild
      },
      decoration: InputDecoration(
        labelText: 'Nominal Pembayaran TUNAI',
        hintText: 'Masukkan nominal',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Silakan masukkan nominal pembayaran';
        }
        final numericValue =
            int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
        if (numericValue == null || numericValue <= 0) {
          return 'Nominal tidak valid';
        }
        return null;
      },
    );
  }

  // Reference Input for Non-TUNAI Methods
  Widget _buildReferenceInput() {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: 'Referensi Pembayaran',
        hintText: 'Masukkan nomor referensi',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Silakan masukkan referensi pembayaran';
        }
        return null;
      },
    );
  }

  // Keterangan Diskon
  Widget _buildDiscountInfo(String discountData) {
    if (discountData.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final discountMap = discountMaps(discountData);
      return _buildDiscountUI(discountMap);
    } catch (e) {
      print('Error parsing discount data: $e');
      return const SizedBox.shrink();
    }
  }

  // Extracted the UI building logic to a separate method
  Widget _buildDiscountUI(Map<String, dynamic> discountMap) {
    if (discountMap['status'] != 'sukses') {
      return const SizedBox.shrink();
    }
    final double totalDiscount =
        _parseDouble(discountMap['total_discount']) ?? 0.0;
    final List<dynamic> discountDetails = discountMap['discount_details'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Discount Details Section
          if (discountDetails.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Text(
                'Detail Item Diskon',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _primaryColor,
                ),
              ),
            ),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Diskon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Harga',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 0.1, color: Colors.grey),

            // Items list with limited visible items and scroll capability
            Container(
              constraints: BoxConstraints(
                // Calculate height based on 2 items
                // Each item is approximately ~76 pixels tall (12 vertical padding x 2 + ~40 content + 12 divider)
                maxHeight: discountDetails.length > 2 ? 152.0 : double.infinity,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                // Only use scrolling physics when there are more than 2 items
                physics: discountDetails.length > 2
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: discountDetails.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 0.1, color: Colors.grey),
                itemBuilder: (context, index) {
                  final item = discountDetails[index];
                  final double discountAmount =
                      _parseDouble(item['discount_amount']) ?? 0.0;
                  final bool hasDiscount = discountAmount > 0;
                  final double originalPrice =
                      _parseDouble(item['original_price']) ?? 0.0;
                  final double finalPrice =
                      _parseDouble(item['final_price']) ?? 0.0;
                  final double qty = _parseDouble(item['qty']) ?? 0.0;
                  final String discountPercentage =
                      item['discount_percentage'] ?? '0%';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['item_name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${qty.toStringAsFixed(0)}x',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasDiscount
                                      ? _primaryColor.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  discountPercentage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hasDiscount
                                        ? _primaryColor
                                        : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatter.format(originalPrice * qty),
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: hasDiscount
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: hasDiscount
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatter.format(finalPrice),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Show scroll indicator if more than 2 items
            if (discountDetails.length > 2)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Geser untuk lihat ${discountDetails.length - 2} item lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Helper method to safely parse double values
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // TUNAI Payment Status Widget
  Widget _buildCashPaymentStatus(double totalPrice) {
    final cashStatus = _calculateCashPaymentStatus(totalPrice);

    if (cashStatus == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: cashStatus == -1
            ? LinearGradient(
                colors: [Colors.red.shade100, Colors.red.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            cashStatus == -1
                ? Icons.warning_rounded
                : cashStatus == 0
                    ? Icons.check_circle_rounded
                    : Icons.monetization_on_rounded,
            color: cashStatus == -1
                ? Colors.red.shade700
                : cashStatus == 0
                    ? Colors.green.shade700
                    : Colors.green.shade700,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cashStatus == -1
                  ? 'Uang Kurang: ${_formatter.format(totalPrice - int.parse(_cashAmountController.text.replaceAll(RegExp(r'[^\d]'), '')))} belum mencukupi'
                  : cashStatus == 0
                      ? 'Pembayaran Pas'
                      : 'Kembalian: ${_formatter.format(cashStatus)}',
              style: TextStyle(
                color: cashStatus == -1
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpanKeranjang() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Memastikan tombol melebar penuh
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Color(0xFF533F77),
            ),
            onPressed: () {
              _handleSimpanKeranjang();
            },
            child: Text('Simpan Keranjang', style: TextStyle(fontSize: 14)),
          ),
        ),
        SizedBox(height: 16), // Jarak antara tombol
        SizedBox(
          width: double.infinity,
          child: isLoading
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Color(0xFF533F77)
                        .withOpacity(0.7), // Warna lebih pudar saat loading
                  ),
                  onPressed: null, // Nonaktifkan tombol saat loading
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Memproses...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Color(0xFF533F77),
                  ),
                  onPressed: () {
                    _handleBuatPesanan();
                  },
                  child: Text('Buat Pesanan', style: TextStyle(fontSize: 14)),
                ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<String>(
      value: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF533F77),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF533F77),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to parse values with appropriate types
  static dynamic _parseValue(String value) {
    value = value.trim();
    // Try parsing as double
    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
      return double.tryParse(value);
    }
    // Try parsing as int
    else if (RegExp(r'^\d+$').hasMatch(value)) {
      return int.tryParse(value);
    }
    // Return as string for everything else
    return value;
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
    EdgeInsetsGeometry? padding,
    double? fontSize,
    double? iconSize,
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
    final borderRadius = BorderRadius.circular(8);

    // Non-clickable widget
    if (!isClickable) {
      return Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(color: _borderColor),
        ),
        child: hasLabel
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: _iconColor, size: iconSize ?? 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: fontSize ?? 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            : Icon(icon, color: _iconColor, size: iconSize ?? 16),
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
              icon: Icon(icon, color: _iconColor, size: iconSize ?? 16),
              label: Text(
                label,
                style: TextStyle(
                  color: _textColor,
                  fontSize: fontSize ?? 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              style: TextButton.styleFrom(
                padding: padding ??
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(10, 36),
                backgroundColor: _backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                ),
                elevation: 0,
              ),
              onPressed: onPressed,
            )
          : TextButton(
              child: Icon(icon, color: _iconColor, size: iconSize ?? 20),
              style: TextButton.styleFrom(
                padding: padding ?? const EdgeInsets.all(2),
                minimumSize: const Size(10, 36),
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

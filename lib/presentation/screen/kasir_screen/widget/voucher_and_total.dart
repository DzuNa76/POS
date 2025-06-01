import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/app_state.dart';
import 'package:pos/core/providers/voucher_provider.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/notification.dart';

import 'package:pos/data/api/mode_of_payment_data.dart' as mode_of_payment;

class VoucherAndTotalWidget extends StatefulWidget {
  final dynamic cashAmount;
  final String? paymentMethod;
  final dynamic referensi;
  final String? channel;

  const VoucherAndTotalWidget(
      {Key? key,
      this.cashAmount,
      this.paymentMethod,
      this.referensi,
      this.channel})
      : super(key: key);

  @override
  State<VoucherAndTotalWidget> createState() => _VoucherAndTotalWidgetState();
}

class _VoucherAndTotalWidgetState extends State<VoucherAndTotalWidget> {
  bool isLoading = false;
  bool _isLoadingVisible = false;
  bool _isSuccessDialogVisible = false;

  void _handleBayar() async {
    if (!_validateCart()) return;

    setState(() => isLoading = true);
    showLoading(message: 'Memproses pesanan...');

    try {
      final cashAmount = double.tryParse(widget.cashAmount.toString()) ?? 0.0;
      final pesananList = await _loadPesanan();

      if (_isFromOrder(pesananList)) {
        await _processFromOrder(pesananList, cashAmount);
      } else {
        await _processNewOrder(cashAmount);
      }
    } catch (e) {
      _handleError('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        hideLoading();
      }
    }
  }

  bool _validateCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    if (cartProvider.cartItems.isEmpty) {
      _showMessage('Keranjang Kosong', isError: true);
      return false;
    }

    if (customerProvider.customer == null) {
      _showMessage('Customer Kosong', isError: true);
      return false;
    }

    return true;
  }

  Future<List<dynamic>> _loadPesanan() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return await cartProvider.loadPesanan();
  }

  bool _isFromOrder(List<dynamic> pesananList) {
    return pesananList.any(
        (a) => a['invoiceNumber'] != null && a['invoiceNumber'].isNotEmpty);
  }

  String _getInvoiceId(List<dynamic> pesananList) {
    try {
      return pesananList.firstWhere(
            (element) =>
                element['invoiceNumber'] != null &&
                element['invoiceNumber'].isNotEmpty,
            orElse: () => {'invoiceNumber': ''},
          )['invoiceNumber'] ??
          '';
    } catch (e) {
      print('Error getting invoice ID: $e');
      return '';
    }
  }

  Future<void> _processFromOrder(
      List<dynamic> pesananList, double cashAmount) async {
    print('ini dari pesanan');

    String invoiceId = _getInvoiceId(pesananList);
    if (invoiceId.isEmpty) {
      _handleError('Invoice ID tidak ditemukan');
      return;
    }

    var response = await SalesDataActions.updateSalesInvoiceToPaid(
      invoiceId: invoiceId,
      totalAmount: cashAmount,
      modeOfPayment: widget.paymentMethod.toString(),
      remarks:
          widget.paymentMethod.toString() != 'TUNAI' ? widget.referensi : null,
    );

    if (response['status'] == 'success') {
      await _handlePrintPesanan(invoiceId);
      await _handleSuccessOrder(
          invoiceId,
          pesananList[0]['customerName'] ?? "_",
          pesananList[0]['customerAddress'] ?? "_",
          pesananList[0]['customerPhone'] ?? "_");
    } else {
      _handleError('Failed to create order: $response');
    }
  }

  Future<void> _processNewOrder(double cashAmount) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    final dataItems = _prepareDataItems(cartProvider.cartItems);

    var responseAccount = await mode_of_payment
        .getModeOfPaymentPerItem(widget.paymentMethod.toString());

    var defaultAccount =
        responseAccount!['data']['accounts'][0]['default_account'];

    final channels = widget.channel ?? 'OFFLINE';
    log(widget.paymentMethod.toString());

    final paymentMethod = widget.paymentMethod.toString();

    if (paymentMethod == 'KASBON') {
      cashAmount = 0;
    }

    var response = await SalesDataActions.postBayarPaidSalesInvoice(
      customerCode: customerProvider.customer!.code.toString(),
      dataItems: dataItems,
      modeOfPayment: paymentMethod,
      defaultAccount: defaultAccount,
      totalAmount: cashAmount,
      channel: channels,
      remarks:
          widget.paymentMethod.toString() != 'TUNAI' ? widget.referensi : null,
    );

    final responseJson = await response;
    if (responseJson['status'] == 'success') {
      final message = jsonDecode(responseJson['message']);
      final name = message['data']['name'];
      final customer_name = message['data']['customer_name'];
      final custom_address = message['data']['custom_address'];
      final custom_phone = message['data']['custom_customer_phone'];

      await _handlePrintPesanan(name);
      await _handleSuccessOrder(name, customer_name ?? '_',
          custom_address ?? "_", custom_phone ?? "_");
    } else {
      _handleError('Failed to create order: $responseJson');
    }
  }

  List<Map<String, dynamic>> _prepareDataItems(List<dynamic> cartItems) {
    return cartItems.map((item) {
      final discount = item.priceListRate - item.amount;
      return {
        "idx": 1,
        "item_code": item.itemCode,
        "item_name": item.itemName,
        "stock_uom": item.uom,
        "description": item.description,
        "qty": item.qty,
        "discount_amount": discount,
        "price_list_rate": item.priceListRate,
        "rate": item.amount,
        "amount": item.amount
      };
    }).toList();
  }

  Future<void> _handlePrintPesanan(String invoiceID) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterIp = prefs.getString('printer_settings') ?? '';

    if (savedPrinterIp.isNotEmpty) {
      final data = json.decode(savedPrinterIp);
      final ip = data['printer_ip'];
      final printerName = data['printer_name'];

      var response = await SalesDataActions.printReceipt(
        invoiceId: invoiceID,
        ipAddress: ip,
        printerName: printerName,
      );

      print(jsonEncode(response));
    }
  }

  Future<void> _handleSuccessOrder(String invoiceID, String customer_name,
      String customer_address, String customer_phone) async {
    print('Order successfully created!');

    showSuccessDialog(
      title: 'Transaksi Berhasil',
      message: 'Pesanan telah berhasil dibuat!',
      actions: [
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.receipt_long,
              label: 'Cetak Struk',
              color: Colors.blue,
              onPressed: () async {
                // Implement your print receipt logic here
                showLoading(message: 'Printing Receipt...');
                await _handlePrintPesanan(
                  invoiceID,
                );
                hideLoading();
              },
            ),
            SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.receipt,
              label: 'Cetak Resi',
              color: Colors.indigo,
              onPressed: () async {
                showLoading(message: 'Printing Resi...');
                await _printResi(
                  customer_name,
                  customer_address,
                  customer_phone,
                  invoiceID,
                );
                hideLoading();
              },
            ),
          ],
        ),
        SizedBox(height: 20),
        // Close button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (mounted) {
                final cartProvider =
                    Provider.of<CartProvider>(context, listen: false);
                final customerProvider =
                    Provider.of<CustomerProvider>(context, listen: false);

                // Perform cleanup actions
                customerProvider.deleteCustomer();
                cartProvider.clearCart();

                // Load pesanan list and delete each one
                final pesananList = await cartProvider.loadPesanan();
                for (var pesanan in pesananList) {
                  cartProvider.deletePesananById(pesanan['invoiceNumber']);
                }

                // Navigate to the next screen
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        KasirScreenDesktop(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tutup',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleError(String message) {
    print(message);
    _showMessage(message, isError: true);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

// Fungsi untuk mencetak resi
  Future<void> _printResi(String customer_name, String customer_address,
      String customer_phone, String invoice_id) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterIp = prefs.getString('printer_resi_settings') ?? '';

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      if (savedPrinterIp.isNotEmpty) {
        final data = json.decode(savedPrinterIp);
        final ip = data['printer_ip'];
        final printerName = data['printer_name'];
        final response = await SalesDataActions.printResi(
            customerName: customer_name,
            customerAddress: customer_address,
            customerPhone: customer_phone,
            senderName: "Monroe Boutique",
            senderAddress: "Jl. Terusan Dieng 52, Malang",
            senderPhone: "085707413498",
            invoiceId: invoice_id,
            ipAddress: ip,
            printerName: printerName);

        print(response);

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> showSuccessDialog({
    String title = 'Berhasil',
    required String message,
    List<Widget>? actions,
    VoidCallback? onClose,
  }) async {
    if (_isSuccessDialogVisible) return;

    // Pastikan loading dialog sudah dihilangkan
    if (_isLoadingVisible) {
      await hideLoading();
    }

    _isSuccessDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, scale, _) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 350,
                      padding: EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Success icon with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, _) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24),

                          // Success text with fade animation
                          AnimatedOpacity(
                            opacity: value,
                            duration: Duration(milliseconds: 500),
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          // Actions with fade animation
                          AnimatedOpacity(
                            opacity: value,
                            duration: Duration(milliseconds: 600),
                            child: actions != null && actions.isNotEmpty
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: actions,
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        if (onClose != null) onClose();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        'Tutup',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    _isSuccessDialogVisible = false;
  }

  Future<void> showLoading({String message = 'Memproses...'}) async {
    // Jika tidak ada context atau loading sudah ditampilkan, keluar
    if (_isLoadingVisible) {
      return;
    }

    _isLoadingVisible = true;

    // Menampilkan dialog loading dengan animasi
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => WillPopScope(
        onWillPop: () async =>
            false, // Mencegah dialog ditutup dengan back button
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated loading spinner
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: null,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Loading text with fade in animation
                      AnimatedOpacity(
                        opacity: value,
                        duration: Duration(milliseconds: 500),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            height: 1.3,
                            color: Colors.black87,
                          ),
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
    );
  }

  Future<void> hideLoading() async {
    if (!_isLoadingVisible) {
      return;
    }

    _isLoadingVisible = false;
    Navigator.of(context).pop();

    // Tunggu sebentar untuk efek visual yang lebih baik
    await Future.delayed(Duration(milliseconds: 200));
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _showNoItemsPopup() {
    showCustomPopup(
      context: context,
      title: "Info",
      icon: Icons.info,
      iconColor: Colors.blue,
      message: "Tidak ada item di keranjang",
      confirmText: "OK",
      duration: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Consumer2<AppState, VoucherProvider>(
      builder: (context, appState, voucherProvider, child) {
        final cartProvider = context.watch<CartProvider>();
        double totalPrice = cartProvider.totalPrice;
        int totalItems = cartProvider.totalItems;

        // Terapkan diskon voucher global jika ada
        if (voucherProvider.selectedVoucher != null &&
            voucherProvider.selectedVoucher!.isGlobal) {
          totalPrice = totalPrice -
              ((totalPrice * voucherProvider.selectedVoucher!.discount) ~/ 100);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : totalItems > 0
                            ? _handleBayar
                            : _showNoItemsPopup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: isLoading
                          ? Colors.grey
                          : totalItems > 0
                              ? Color(0xFF533F77)
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _buildButtonContent(totalItems, totalPrice, formatter),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(
      int totalItems, double totalPrice, NumberFormat formatter) {
    if (totalItems <= 0) {
      return Center(
        child: Text(
          'Tambahkan Item',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bayar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$totalItems item',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              formatter.format(widget.cashAmount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ],
    );
  }
}

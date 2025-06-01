import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/invoice_model.dart';
import 'package:pos/data/models/payment_model.dart';
import 'package:pos/data/models/voucher.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/presentation/screen/payment_screen/receipt_screen.dart';
import 'package:provider/provider.dart';

class MobilePaymentScreen extends StatefulWidget {
  final int totalTagihan;
  final List<CartItem> orders;
  final Voucher? voucher;
  final String? customerName;
  final String orderType;

  const MobilePaymentScreen({
    required this.totalTagihan,
    required this.orders,
    this.voucher,
    this.customerName,
    required this.orderType,
  });

  @override
  _MobilePaymentScreenState createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _modeOfPayment;
  String? _referenceNumber;
  String? _account;
  int? _cashAmount;
  Payment? _payment;
  Invoice? _salesInvoice;
  String _customerName = "Guest";
  late String orderType;

  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern('id');

  @override
  void initState() {
    super.initState();
    // Initialize customer name from widget if provided
    if (widget.customerName != null && widget.customerName!.isNotEmpty) {
      _customerName = widget.customerName!;
    }

    orderType = widget.orderType;
  }

  String getAccountForPaymentMethod(String? method) {
    switch (method) {
      case "Cash":
        return "1111.001 - Kas Kecil - M";
      case "Credit Card":
        return "1121.001 - Bank BCA - M"; // Sesuaikan dengan akun yang benar
      case "Bank Transfer":
        return "1122.001 - Bank Mandiri - M"; // Sesuaikan dengan akun yang benar
      default:
        return "1111.001 - Kas Kecil - M";
    }
  }

  void _updatePaymentAndInvoice() {
    if (_formKey.currentState!.validate()) {
      // Create Payment object
      final payment = Payment(
        modeOfPayment: _modeOfPayment!,
        amount: _modeOfPayment == "Cash"
            ? _cashAmount!.toDouble()
            : widget.totalTagihan.toDouble(),
        baseAmount: widget.totalTagihan.toDouble(),
        referenceNumber:
            _modeOfPayment == "Cash" ? 'CASH_PAYMENT' : _referenceNumber!,
        account: _modeOfPayment == "Cash" ? 'Cash Drawer' : _account!,
      );

      // Create SalesInvoice object
      final salesInvoice = Invoice(
        docstatus: 1,
        namingSeries: 'SINV-',
        company: 'Your Company Name',
        costCenter: 'Main - CC',
        postingDate: DateTime.now().toString().split(' ')[0],
        postingTime: TimeOfDay.now().format(context),
        setPostingTime: 1,
        isPos: 1,
        currency: 'IDR',
        conversionRate: 1,
        sellingPriceList: 'Standard Selling',
        priceListCurrency: 'IDR',
        baseNetTotal: widget.totalTagihan.toDouble(),
        baseGrandTotal: widget.totalTagihan.toDouble(),
        grandTotal: widget.totalTagihan.toDouble(),
        customer: 'Guest',
        posProfile: 'Main POS Profile',
        payments: [payment],
        items: widget.orders.map((order) {
          return CartItem(
            id: order.id,
            itemCode: order.itemCode,
            itemName: order.itemName,
            description: order.description,
            uom: order.uom,
            conversionFactor: order.conversionFactor,
            qty: order.qty,
            rate: order.rate,
            amount: order.amount,
            baseRate: order.baseRate,
            baseAmount: order.baseAmount,
            priceListRate: order.priceListRate,
            costCenter: order.costCenter,
          );
        }).toList(),
        updateStock: 1,
        debitTo: 'Debtor - CC',
      );

      setState(() {
        _payment = payment;
        _salesInvoice = salesInvoice;
      });
    }
  }

  void _onCashChanged(String value) {
    // Hapus semua karakter non-numeric
    String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericValue.isNotEmpty) {
      int amount = int.parse(numericValue);
      String formatted = _formatter.format(amount);

      setState(() {
        _cashAmount = amount;
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });
    } else {
      setState(() {
        _cashAmount = 0;
        _controller.clear();
      });
    }
  }

  Future<void> _prosesPembayaran() async {
    if (_formKey.currentState!.validate()) {
      _updatePaymentAndInvoice();

      // Construct payment data according to the API format
      final Map<String, dynamic> paymentData = {
        "docstatus": 1,
        "naming_series": "ACC-SINV-.YYYY.-",
        "company": "Monroe",
        "cost_center": "Main - M",
        "posting_date":
            DateTime.now().toString().split(' ')[0], // Format: YYYY-MM-DD
        "posting_time":
            "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        "set_posting_time": 1,
        "is_pos": 1,
        "currency": "IDR",
        "conversion_rate": 1,
        "selling_price_list": "Standard Selling",
        "price_list_currency": "IDR",
        "base_net_total": widget.totalTagihan.toDouble(),
        "base_grand_total": widget.totalTagihan.toDouble(),
        "grand_total": widget.totalTagihan.toDouble(),
        "customer": "CUST-2024-01641", // Update with actual customer ID
        "pos_profile": "Monroe Pos",
        "payments": [
          {
            "mode_of_payment":
                _modeOfPayment == "Cash" ? "CASH" : _modeOfPayment,
            "amount": _modeOfPayment == "Cash"
                ? _cashAmount!.toDouble()
                : widget.totalTagihan.toDouble(),
            "base_amount": widget.totalTagihan.toDouble(),
            "reference_number":
                _modeOfPayment == "Cash" ? "-" : _referenceNumber,
            "account": getAccountForPaymentMethod(_modeOfPayment),
          }
        ],
        "items": widget.orders
            .map((order) => {
                  "item_code": order.itemCode,
                  "item_name": order.itemName,
                  "description": order.description,
                  "uom": order.uom,
                  "conversion_factor": order.conversionFactor,
                  "qty": order.qty,
                  "rate": order.rate,
                  "amount": order.amount,
                  "base_rate": order.baseRate,
                  "base_amount": order.baseAmount,
                  "price_list_rate": order.priceListRate,
                  "cost_center": "Main - M" // Match with the API example
                })
            .toList(),
        "update_stock": 0,
        "debit_to": "" // This is empty in the API example
      };

      // Posting ke API
      try {
        final response = await http.post(
          Uri.parse('https://monroe.my.id/api/resource/Sales%20Invoice'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie':
                'full_name=Administrator; sid=515976ef5185c5b7f41df98812796f6d8d48c411b4da5bc526384cb6; system_user=yes; user_id=Administrator; user_image=',
            // Add any other required headers from the cURL example
          },
          body: json.encode(paymentData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Berhasil
          print('Sales Invoice berhasil dibuat: ${response.body}');

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Sukses'),
              content: Text('Pembayaran berhasil diproses!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptScreen(
                          totalTagihan: widget.totalTagihan,
                          orders: widget.orders,
                          customerName: _customerName,
                          orderType: widget.orderType,
                          cashAmount: _cashAmount,
                          modeOfPayment: _modeOfPayment,
                          referenceNumber: _referenceNumber,
                          kembalian: _kembalian,
                        ),
                      ),
                    );
                    // Optionally navigate back to previous screen or clear cart
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Error dari server
          print(
              'Gagal membuat Sales Invoice: ${response.statusCode} - ${response.body}');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Gagal'),
              content: Text(
                  'Terjadi kesalahan saat memproses pembayaran.\nKode: ${response.statusCode}\nPesan: ${response.body}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Error jaringan atau lainnya
        print('Error: $e');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Tidak dapat terhubung ke server.\nError: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Calculate kembalian
  int get _kembalian {
    if (_modeOfPayment == "Cash" && _cashAmount != null) {
      return _cashAmount! - widget.totalTagihan;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Pembayaran',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Total Tagihan:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            formatter.format(widget.totalTagihan),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Total Dibayar:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            formatter
                                .format(_cashAmount ?? widget.totalTagihan),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Kembalian:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            formatter.format(_kembalian),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Order Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Pesanan:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          ...widget.orders.map((order) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${order.itemName}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${order.qty ?? 0} x ${formatter.format(order.rate ?? 0)}',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            formatter.format(order.amount),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('ID: ${order.itemCode}',
                                          style: TextStyle(fontSize: 12)),
                                      if (order.description != null &&
                                          order.description!.isNotEmpty)
                                        Text(
                                            'Description: ${order.description}',
                                            style: TextStyle(fontSize: 12)),
                                      if (order.notes != null)
                                        Text('Catatan: ${order.notes}',
                                            style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Pembayaran:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Metode Pembayaran'),
                          items: ['Cash', 'Credit Card', 'Bank Transfer']
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _modeOfPayment = value;
                              // Reset input values
                              _referenceNumber = null;
                              _cashAmount = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Pilih metode pembayaran' : null,
                        ),
                        const SizedBox(height: 8),
                        if (_modeOfPayment == "Cash")
                          TextFormField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Nominal Cash',
                              prefixText: 'Rp. ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _onCashChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Masukkan nominal cash';
                              }
                              if (_cashAmount != null &&
                                  _cashAmount! < widget.totalTagihan) {
                                return 'Nominal kurang dari total tagihan';
                              }
                              return null;
                            },
                          )
                        else if (_modeOfPayment != null)
                          Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'Nomor Referensi'),
                                onChanged: (value) {
                                  setState(() {
                                    _referenceNumber = value;
                                  });
                                },
                                validator: (value) {
                                  if (_modeOfPayment != "Cash" &&
                                      (value == null || value.isEmpty)) {
                                    return 'Masukkan nomor referensi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'Akun Pembayaran'),
                                onChanged: (value) {
                                  setState(() {
                                    _account = value;
                                  });
                                },
                                validator: (value) {
                                  if (_modeOfPayment != "Cash" &&
                                      (value == null || value.isEmpty)) {
                                    return 'Masukkan akun pembayaran';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _prosesPembayaran,
                          child: Text('Proses Pembayaran'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

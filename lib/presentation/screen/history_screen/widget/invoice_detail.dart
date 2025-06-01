import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/utils/config.dart';
import 'dart:math' as math;
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:pos/presentation/screen/history_screen/sales_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceDetail extends StatefulWidget {
  final SalesInvoice? invoice;
  final Function(SalesInvoice) onPrintResi;
  final Function(SalesInvoice) onPrint;
  final bool isLoading;

  const InvoiceDetail({
    Key? key,
    required this.invoice,
    required this.onPrintResi,
    required this.onPrint,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<InvoiceDetail> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends State<InvoiceDetail> {
  bool isLoading = false;
  bool _discountPerItem = false;
  bool isHasRolestoCancel = false;
  bool isHasRolestoReturnItem = false;

  @override
  void initState() {
    super.initState();
    isLoading = widget.isLoading;
    checkRoles();
    _checkSettingPos();
  }

  @override
  void didUpdateWidget(InvoiceDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      setState(() {
        isLoading = widget.isLoading;
      });
    }
  }

  void checkRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('roles');

    if (roleString == null) return;

    final List<dynamic> roles = jsonDecode(roleString);

    setState(() {
      isHasRolestoCancel = roles.any((r) => r['role'] == 'Sales Manager');
      isHasRolestoReturnItem = roles.any((r) => r['role'] == 'Sales Manager');
    });
  }

  Future<void> _checkSettingPos() async {
    final prefs = await SharedPreferences.getInstance();

    final discountPerItem = prefs.getBool('discount_per_item') ?? false;

    if (mounted) {
      setState(() {
        _discountPerItem = discountPerItem;
      });
    }
  }

  // Custom Rupiah formatter
  String _formatRupiah(num amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String formatAddress(String text) {
    List<String> parts = text.split(', ');
    if (parts.length <= 3) {
      return text; // Biarkan tetap satu baris jika koma kurang dari 3
    }

    List<String> formattedLines = [];
    for (int i = 0; i < parts.length; i += 3) {
      formattedLines.add(parts
          .sublist(i, i + 3 > parts.length ? parts.length : i + 3)
          .join(', '));
    }

    return formattedLines.join('\n');
  }

  double _calculateKembalian() {
    // Sum up all payment amounts
    double totalPaid = 0;
    for (var payment in widget.invoice!.mode_of_payment) {
      totalPaid += payment.amount;
    }

    // Calculate change as totalPaid - invoiceTotal
    return totalPaid - widget.invoice!.total;
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (var item in widget.invoice!.items) {
      subtotal += (item.priceListRate * item.qty);
    }

    return subtotal;
  }

  double _calculateTotalDiscount() {
    double totalDiscount = 0;
    for (var item in widget.invoice!.items) {
      totalDiscount += item.discountAmount * item.qty;
    }

    return totalDiscount;
  }

  void _showReturnModal(BuildContext context) {
    // Filter out items with qty of 0
    final itemsToShow =
        widget.invoice!.items.where((item) => item.qty > 0).toList();

    if (itemsToShow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua item sudah di-return'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_return_rounded,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Return Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Pilih item yang ingin dikembalikan dari pesanan ini',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemsToShow.length,
                    itemBuilder: (context, index) {
                      final item = itemsToShow[index];
                      return Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        margin: EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            // Close the first dialog
                            Navigator.of(dialogContext).pop();

                            // Create a BuildContext variable to reference the processing dialog
                            BuildContext? processingDialogContext;

                            // Show processing dialog that can't be dismissed
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext ctx) {
                                // Save the context reference to use for closing
                                processingDialogContext = ctx;

                                return WillPopScope(
                                  onWillPop: () async =>
                                      false, // Prevent back button
                                  child: Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.red[400]!),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Memproses Return...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '${item.itemName}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                            // Process the return
                            try {
                              // Uncomment dan gunakan API asli
                              final success = await SalesDataActions
                                  .returnSalesInvoiceItemAction(
                                customer: widget.invoice!.customer,
                                originalInvoiceId: widget.invoice!.name,
                                itemCode: item.itemCode,
                                qty: item.qty,
                                rate: item.rate,
                                modeOfPayment: widget.invoice!.mode_of_payment,
                              );

                              // Close processing dialog after successful API call
                              if (processingDialogContext != null) {
                                Navigator.of(processingDialogContext!).pop();
                              }

                              // Show success message
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Item berhasil di-return'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }

                              // Update local state if needed
                              if (mounted) {
                                setState(() {
                                  isLoading = true;
                                });

                                // Refresh data
                                await Future.delayed(
                                    Duration(milliseconds: 500));

                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }

                                _reloadPage();
                              }
                            } catch (e) {
                              // Close processing dialog
                              if (processingDialogContext != null) {
                                Navigator.of(processingDialogContext!).pop();
                              }

                              // Show error message
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Return gagal: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item.description ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'x${item.qty}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatRupiah(item.rate ?? 0),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelSalesInvoiceDialog(BuildContext context, SalesInvoice item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Batalkan Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Anda yakin ingin membatalkan ${item.name}?',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading dialog
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.red[400],
                            ),
                            SizedBox(width: 20),
                            Text(
                              'Memproses...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                try {
                  final response = await SalesDataActions.cancelSalesInvoice(
                    item.name.toString(),
                  );

                  print(response.name);

                  // Close loading dialog
                  Navigator.of(dialogContext).pop();
                  // Close main dialog
                  Navigator.of(dialogContext).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice berhasil dibatalkan'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SalesHistoryPage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(dialogContext).pop();

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Gagal membatalkan Invoice: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _reloadPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SalesHistoryPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoice == null) {
      return const Center(child: Text('Pilih Invoice untuk melihat detail'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: ReceiptPainter(),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: isLoading
                        ? Center(
                            heightFactor: 5,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.15,
                              child: Align(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Restaurant Header
                              Image.asset(
                                ConfigService.logo,
                                width: 120,
                                height: 50,
                              ),
                              Text(
                                formatAddress(
                                    'Jl. Terusan Dieng No.52, Pisang Candi, Kec. Sukun, Kota Malang, Jawa Timur 65146'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                ('0341568474'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dash Separator
                              _buildDashSeparator(),
                              const SizedBox(height: 16),

                              // Invoice Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'No',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.invoice!.name,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tgl Transaksi',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.invoice!.postingDate,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Customer',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.invoice!.customerName,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildDashSeparator(),
                              const SizedBox(height: 16),

                              // Item List
                              ListView.separated(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: widget.invoice!.items.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.black12,
                                  height: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final item = widget.invoice!.items[index];
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.status != ''
                                                ? '[${item.status}] ${item.itemName ?? ''} '
                                                : '${item.itemName ?? ''} ',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            "${item.qty} X ${_formatRupiah(item.priceListRate)} ${_discountPerItem ? "(-${item.status != '' ? 0 : _formatRupiah(item.discountAmount)})" : ""}" ??
                                                '',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatRupiah(_discountPerItem
                                            ? item.status != ''
                                                ? 0
                                                : (item.priceListRate *
                                                        item.qty) -
                                                    item.discountAmount
                                            : (item.priceListRate * item.qty)),
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Dash Separator

                              Container(
                                child: _discountPerItem
                                    ? Container()
                                    : Column(
                                        children: [
                                          _buildDashSeparator(),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Subtotal',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black)),
                                              Text(
                                                _formatRupiah(
                                                    _calculateSubtotal()),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Discount',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black)),
                                              Text(
                                                _formatRupiah(
                                                    _calculateTotalDiscount()),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                              ),

                              // Dash Separator
                              _buildDashSeparator(),
                              const SizedBox(height: 16),

                              // Total
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                  Text(
                                    _formatRupiah(widget.invoice!.total),
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Dash Separator
                              _buildDashSeparator(),

                              const SizedBox(height: 16),

                              // Payment
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount:
                                    widget.invoice!.mode_of_payment.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          widget.invoice!.mode_of_payment[index]
                                              .mode,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(widget.invoice!
                                              .mode_of_payment[index].amount),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Kembalian',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                  Text(
                                    _formatRupiah(_calculateKembalian()),
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 42),
                              Text(
                                'Terima kasih',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            if (widget.invoice!.status != 'Cancelled' &&
                widget.invoice!.status != 'Draft')
              Container(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 8),
                child: Column(
                  children: [
                    // Baris pertama: Tombol Cetak
                    Row(
                      children: [
                        // Tombol Cetak Struk (kiri)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLoading
                                  ? Colors.grey[300]
                                  : Colors.blue[600],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => widget.onPrint(widget.invoice!),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Cetak Struk',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tombol Cetak Resi (kanan)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLoading
                                  ? Colors.grey[300]
                                  : Colors.green[600],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => widget.onPrintResi(widget.invoice!),
                            icon: const Icon(
                              Icons.local_shipping_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Cetak Resi',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isHasRolestoReturnItem)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Row(
                          children: [
                            // Tombol Return Item (kiri)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLoading
                                      ? Colors.grey[200]
                                      : Colors.orange[50],
                                  foregroundColor: isLoading
                                      ? Colors.grey[500]
                                      : Colors.orange[900],
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isLoading
                                          ? Colors.grey[300]!
                                          : Colors.orange[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () => _showReturnModal(context),
                                icon: Icon(
                                  Icons.assignment_return_rounded,
                                  color: isLoading
                                      ? Colors.grey[500]
                                      : Colors.orange[700],
                                  size: 20,
                                ),
                                label: Text(
                                  'Return Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tombol Cancel (kanan)
                            if (isHasRolestoCancel)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLoading
                                        ? Colors.grey[200]
                                        : Colors.red[50],
                                    foregroundColor: isLoading
                                        ? Colors.grey[500]
                                        : Colors.red[800],
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isLoading
                                            ? Colors.grey[300]!
                                            : Colors.red[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => _showCancelSalesInvoiceDialog(
                                          context, widget.invoice!),
                                  icon: Icon(
                                    Icons.cancel_rounded,
                                    color: isLoading
                                        ? Colors.grey[500]
                                        : Colors.red[700],
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Cancel Invoice',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  // Helper method to create dash separator
  Widget _buildDashSeparator() {
    return Row(
      children: List.generate(
        80,
        (index) => Expanded(
          child: Container(
            height: 1,
            color: index % 2 == 0 ? Colors.black12 : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class ReceiptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    const double jagged = 5.0; // Ukuran sobekan lebih kecil dan seragam
    const double shadowOffset = 3.0;

    // Shadow path
    final shadowPath = Path();
    shadowPath.addPath(
        _createTornEdgePath(size, jagged), Offset(shadowOffset, shadowOffset));

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(shadowPath, shadowPaint);

    // Main receipt path
    path.addPath(_createTornEdgePath(size, jagged), Offset.zero);

    // Slight texture
    final texturePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.grey.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
    canvas.drawPath(path, texturePaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  Path _createTornEdgePath(Size size, double jagged) {
    final path = Path();

    // Main rectangle
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Top edge with uniform torn effect
    for (double i = 0; i < size.width; i += jagged * 2) {
      path.lineTo(i + jagged / 2, -jagged); // Turun ke bawah
      path.lineTo(i + jagged * 1.5, 0); // Naik ke atas
    }
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);

    // Bottom edge with uniform torn effect
    for (double i = size.width; i > 0; i -= jagged * 2) {
      path.lineTo(i - jagged / 2, size.height + jagged); // Naik ke atas
      path.lineTo(i - jagged * 1.5, size.height); // Turun ke bawah
    }
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

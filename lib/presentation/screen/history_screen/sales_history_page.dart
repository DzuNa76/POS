import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/providers/mode_of_payment.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/payment_model.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:pos/presentation/screen/history_screen/widget/invoice_detail.dart';
import 'package:pos/presentation/screen/history_screen/widget/invoice_list.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:pos/presentation/screen/setting_desktop_screen/setting_desktop_screen.dart';
import 'package:pos/presentation/widgets/Alert/dialog_modal.dart';
import 'package:pos/presentation/widgets/sidebar_menu.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({Key? key}) : super(key: key);

  @override
  _SalesHistoryPageState createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  List<SalesInvoice> _salesInvoices = [];
  SalesInvoice? _selectedInvoice;
  TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<SalesInvoice> _filteredInvoices = [];
  List<String> _paymentMethods = [""]; // Default agar tidak kosong
  String? _selectedPaymentMethod = "TUNAI";
  bool isLoading = true;
  String dateStart = '';
  String dateEnd = '';
  String modeOfPayment = '';
  String searchQuery = '';
  Timer? _debounce;
  List<SalesInvoice> _returnInvoices = [];
  SalesInvoice? _selectedReturnInvoice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInvoices();
    });
    _loadModeOfPayment();
  }

  void onSearchChanged(String query) {
    searchQuery = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 750), () {
      _handleSearch();
    });
  }

  void _loadModeOfPayment() async {
    final provider = Provider.of<ModeOfPaymentProvider>(context, listen: false);
    final payments = provider.modeOfPayments;

    setState(() {
      _paymentMethods = payments.isNotEmpty
          ? payments.map((payment) => payment.modeOfPayment).toList()
          : ["TUNAI"]; // Gunakan "TUNAI" jika kosong

      // Pastikan _selectedPaymentMethod ada di dalam daftar
      _selectedPaymentMethod = _paymentMethods.contains(_selectedPaymentMethod)
          ? _selectedPaymentMethod
          : _paymentMethods.first;
    });
  }

  // Fungsi untuk mengambil invoice
  Future<void> _fetchInvoices() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      // final data = await SalesDataActions.getDatas(50, 0, searchsearchQuery);
      final datas = await SalesDataActions.getAllDatas();

      if (mounted) {
        setState(() {
          // salesData = datas;
          _salesInvoices = datas;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print(e);
    }
  }

  Future<void> handleCreditNoteInvoice(SalesInvoice invoice) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final datas = await SalesDataActions.getReturDatas(invoice.name);

      // Buat list baru untuk items yang diedit
      List<SalesInvoiceItem> editedItems = [];

      // Salin semua item dari _selectedInvoice
      for (var originalItem in _selectedInvoice!.items) {
        double totalReturnQty = 0;

        // Periksa setiap return invoice dalam datas
        for (var returnInvoice in datas) {
          // Cari item yang sesuai dalam returnInvoice.items
          for (var returnItem in returnInvoice.items) {
            if (returnItem.itemCode == originalItem.itemCode) {
              // Akumulasi total return quantity (biasanya negatif)
              totalReturnQty += returnItem.qty;
            }
          }
        }

        // Hitung qty dan amount baru
        double newQty = originalItem.qty + totalReturnQty;
        double newAmount = newQty * originalItem.rate;
        String stats = '';

        // Jika newQty ≤ 0, tetapkan qty dan amount menjadi 0
        if (newQty <= 0) {
          newQty = 0;
          newAmount = 0;
          stats = 'Return';
        }

        // Tambahkan item dengan qty dan amount yang sudah diupdate
        editedItems.add(SalesInvoiceItem(
            name: originalItem.name,
            itemCode: originalItem.itemCode,
            itemName: originalItem.itemName,
            description: originalItem.description,
            qty: newQty,
            stockUom: originalItem.stockUom,
            priceListRate: originalItem.priceListRate,
            discountPercentage: originalItem.discountPercentage,
            discountAmount: originalItem.discountAmount,
            rate: originalItem.rate,
            amount: newAmount,
            warehouse: originalItem.warehouse,
            status: stats));
      }

      // Kalkulasi ulang total invoice berdasarkan items yang diedit
      double newTotal = 0;
      for (var item in editedItems) {
        newTotal += item.amount;
      }

      // Buat SalesInvoice baru dengan items yang sudah diedit
      SalesInvoice finalEditedInvoice = SalesInvoice(
        name: _selectedInvoice!.name,
        owner: _selectedInvoice!.owner,
        creation: _selectedInvoice!.creation,
        modified: _selectedInvoice!.modified,
        modifiedBy: _selectedInvoice!.modifiedBy,
        docstatus: _selectedInvoice!.docstatus,
        title: _selectedInvoice!.title,
        customer: _selectedInvoice!.customer,
        customerName: _selectedInvoice!.customerName,
        customerPhone: _selectedInvoice!.customerPhone,
        customerAddress: _selectedInvoice!.customerAddress,
        company: _selectedInvoice!.company,
        postingDate: _selectedInvoice!.postingDate,
        total: newTotal,
        netTotal: newTotal,
        grandTotal: newTotal,
        outstandingAmount: _selectedInvoice!.outstandingAmount,
        currency: _selectedInvoice!.currency,
        mode_of_payment: _selectedInvoice!.mode_of_payment,
        items: editedItems,
        paymentSchedule: _selectedInvoice!.paymentSchedule,
        status: _selectedInvoice!.status,
      );

      setState(() {
        _returnInvoices = datas;
        _selectedInvoice = finalEditedInvoice;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print(e);
    }
  }

  Future<void> _handleSearch() async {
    // Check if search query is valid
    if (searchQuery.isNotEmpty && searchQuery.length < 4) {
      return;
    }

    // Set loading state first
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Await for the data to be completely fetched
      final sales = await SalesDataActions.getDataSearch(
          searchQuery.length < 4 ? 10 : 20, 0, searchQuery, '', '', '');

      // After data is fully loaded, update the state once
      if (mounted) {
        setState(() {
          _selectedInvoice = null;
          _salesInvoices = sales;
          isLoading =
              false; // Set loading to false within the same setState call
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        // Also need to set loading to false in case of error
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFilterDate() async {
    if (dateStart.isEmpty || dateEnd.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final sales = await SalesDataActions.getDataSearch(
          1000, 0, searchQuery, dateStart, dateEnd, modeOfPayment);
      if (mounted) {
        setState(() {
          _salesInvoices = sales;
          _selectedInvoice = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFilterPaymentMode() async {
    print(dateStart);
    print(dateEnd);
    if (dateStart.isEmpty || dateEnd.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date range is not selected')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final sales = await SalesDataActions.getDataSearch(
          1000, 0, '', dateStart, dateEnd, modeOfPayment);
      if (mounted) {
        setState(() {
          _salesInvoices = sales;
          _selectedInvoice = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  static String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('+')) {
      return phoneNumber.substring(1); // Remove + if exists
    }
    if (phoneNumber.startsWith('0')) {
      return '62${phoneNumber.substring(1)}'; // Convert 08xx to 628xx
    }
    return phoneNumber;
  }

  // Fungsi untuk berbagi invoice via WhatsApp
  void _shareInvoice(SalesInvoice invoice) async {
    final waPhone = invoice.customerPhone;
    if (waPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak Ada Nomor WhatsApp yang terdaftar')),
      );
      return;
    }
    final formattedNumber = _formatPhoneNumber(waPhone);

    // Tambahkan pesan pembuka yang ramah
    final invoiceDetails = '''
🎉 Terima Kasih Telah Berbelanja! 🛍️

Berikut Detail Struk Pembelian Anda:

📋 Invoice: ${invoice.name}
👤 Pelanggan: ${invoice.customerName}
📅 Tanggal: ${invoice.postingDate}
💰 Total Pembayaran: Rp ${NumberFormat('#,###').format(invoice.total)}
    
🛒 Detail Produk:
${invoice.items.map((item) => '- ${item.itemName} (${item.qty}x) @ Rp ${NumberFormat('#,###').format(item.rate)}').join('\n')}

💳 Metode Pembayaran:
${invoice.mode_of_payment.map((payment) => '- ${payment.mode}: Rp ${NumberFormat('#,###').format(payment.amount)}').join('\n')}

✨ Terima kasih telah memilih layanan kami! 
Semoga Anda puas dengan pelayanan kami. 
Silakan hubungi kami jika ada pertanyaan.

Hormat Kami,
Tim Customer Service 🤝
''';

    final encodedMessage = Uri.encodeComponent(invoiceDetails);
    final whatsappUrl =
        'whatsapp://send?phone=$formattedNumber&text=$encodedMessage';
    print(whatsappUrl);

    if (await canLaunch(whatsappUrl)) {
      // await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp tidak terinstal')),
      );
    }
  }

  // Fungsi untuk print invoice (simulasi)
  Future<void> _printInvoice(SalesInvoice invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrinterIp = prefs.getString('printer_settings') ?? '';
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      if (savedPrinterIp.isNotEmpty) {
        final data = json.decode(savedPrinterIp);
        final ip = data['printer_ip'];
        final printerName = data['printer_name'];
        print(ip);
        final response = await SalesDataActions.printReceipt(
            invoiceId: invoice.name,
            ipAddress: ip,
            printerName: printerName,
            status: "Reprinted");
        if (response != null) {
          showSuccessDialog(
            context: context,
            title: 'Print Status',
            message: 'Print Berhasil',
            description: 'Struk Anda telah berhasil dicetak',
          );
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran Kosong/Belum Dibayar')),
          );
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
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

  Future<void> _printResi(SalesInvoice invoice) async {
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
            customerName: invoice.customerName,
            customerAddress: invoice.customerAddress,
            customerPhone: invoice.customerPhone,
            senderName: "Monroe Boutique",
            senderAddress: "Jl. Terusan Dieng 52, Malang",
            senderPhone: "085707413498",
            invoiceId: invoice.name,
            ipAddress: ip,
            printerName: printerName);

        print(response);

        if (mounted) {
          setState(() {
            isLoading = false;
          });

          showSuccessDialog(
            context: context,
            title: 'Print Status',
            message: 'Print Resi Berhasil',
            description: 'Resi Anda telah berhasil dicetak',
          );
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

  void _openKasirPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            KasirScreenDesktop(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false, // Disable tombol back
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Riwayat',
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
                    Color(0xFF533F77), // Warna utama yang diminta
                    Color(0xFF6A5193), // Variasi lebih terang dari warna utama
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
                onPressed: () => _openKasirPage(),
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
              // Bagian Kiri - List Invoice
              Expanded(
                flex: 4,
                child: InvoiceList(
                  invoices: _salesInvoices,
                  isLoading: isLoading,
                  paymentModes: _paymentMethods,
                  onInvoiceSelected: (invoice) async {
                    print(invoice.status);
                    if (invoice.status == "Credit Note Issued") {
                      // _selectedInvoice = _returnInvoices[0];
                      _selectedInvoice = invoice;
                    } else {
                      setState(() {
                        _selectedInvoice = invoice;
                      });
                    }
                  },
                  onCreditNoteInvoiceSelected: (invoice) {
                    // Your special handler for credit note invoices
                    handleCreditNoteInvoice(invoice);
                  },
                  searchController: _searchController,
                  onDateRangeApplied: (dateRange) {
                    DateFormat formatter = DateFormat('yyyy-MM-dd');
                    String datestart = formatter.format(dateRange.start);
                    String dateend = formatter.format(dateRange.end);

                    setState(() {
                      dateStart = datestart;
                      dateEnd = dateend;
                    });

                    _handleFilterDate();
                  },
                  onPaymentModeSelected: (payment) {
                    setState(() {
                      modeOfPayment = payment;
                    });
                    _handleFilterPaymentMode();
                  },
                  onSearch: (search) {
                    setState(() {
                      searchQuery = search;
                    });
                    onSearchChanged(search);
                  },
                ),
              ),
              VerticalDivider(
                thickness: 1,
                color: Colors.grey[300],
              ),

              // Bagian Kanan - Detail Invoice
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InvoiceDetail(
                    invoice: _selectedInvoice,
                    onPrintResi: _printResi,
                    onPrint: _printInvoice,
                    isLoading: isLoading,
                  ),
                ),
              ),
            ],
          ),
        ));
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

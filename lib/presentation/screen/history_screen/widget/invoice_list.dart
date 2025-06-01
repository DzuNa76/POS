import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:pos/presentation/screen/history_screen/sales_history_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InvoiceList extends StatefulWidget {
  final List<SalesInvoice> invoices;
  final List<String> paymentModes;
  final Function(SalesInvoice) onInvoiceSelected;
  final TextEditingController searchController;
  final Function(DateTimeRange) onDateRangeApplied;
  final Function(String) onPaymentModeSelected;
  final Function(String) onSearch;
  final Function(SalesInvoice)? onCreditNoteInvoiceSelected;

  final bool isLoading;
  const InvoiceList(
      {Key? key,
      required this.invoices,
      required this.paymentModes,
      required this.onInvoiceSelected,
      required this.searchController,
      required this.onDateRangeApplied,
      required this.onPaymentModeSelected,
      required this.onSearch,
      required this.isLoading,
      this.onCreditNoteInvoiceSelected})
      : super(key: key);

  @override
  _InvoiceListState createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMode;
  SalesInvoice? _selectedInvoice;

  // List of payment modes
  List<String> _paymentModes = [
    'Tunai',
    'Transfer',
    'Kartu Kredit',
    'E-Wallet',
    'Semua'
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    getPaymentMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lakukan operasi yang memerlukan setState di sini
      setState(() {
        // Inisialisasi atau pembaruan state
        DateTime today = DateTime.now();
        _startDate = today;
        _endDate = today;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(today);
        _endDateController.text = DateFormat('dd/MM/yyyy').format(today);
      });

      // Trigger date range application dengan tanggal default
      widget.onDateRangeApplied(
          DateTimeRange(start: _startDate!, end: _endDate!));
    });
    super.initState();
  }

  void getPaymentMode() {
    setState(() {
      if (widget.paymentModes.isNotEmpty) {
        _paymentModes = widget.paymentModes;
      }
    });
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    // Determine initial date and first date based on current selections
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    if (isStartDate) {
      initialDate = _startDate ?? DateTime.now();
      if (_endDate != null) {
        lastDate = _endDate!;
      }
    } else {
      initialDate = _endDate ?? DateTime.now();
      if (_startDate != null) {
        firstDate = _startDate!;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('End Date Required'),
                content: const Text('Choose a date after the start date'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              );
            },
          );

          // If end date exists and is before new start date, reset end date
          if (_endDate != null && picked.isAfter(_endDate!)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);

          // If start date exists and is after new end date, reset start date
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _startDate = null;
            _startDateController.clear();
          }

          // Only trigger date range when end date is selected and start date exists
          if (_startDate != null) {
            final dateRange = DateTimeRange(start: _startDate!, end: _endDate!);
            widget.onDateRangeApplied(dateRange);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out invoices with status "Return"
    final filteredInvoices =
        widget.invoices.where((invoice) => invoice.status != "Return").toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Range Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Mulai',
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => {
                              _selectDate(context, true),
                            }),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Selesai',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, false),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar and Payment Mode side by side
          Row(
            children: [
              // Payment Mode Dropdown
              Expanded(
                  flex: 2,
                  child: CustomDropdown<String>.search(
                    searchHintText: "Cari Metode Pembayaran",
                    closedHeaderPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    hintText: "Pilih Metode Pembayaran",
                    items: _paymentModes,
                    initialItem: _selectedPaymentMode,
                    decoration: CustomDropdownDecoration(
                        closedBorder: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                          top:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                          left:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                          right:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        closedFillColor: Colors.grey.shade100),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMode = value;
                        widget.onPaymentModeSelected(value!);
                      });
                    },
                  )),
              const SizedBox(width: 16),

              // Search Bar
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari invoice...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          widget.onSearch(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(thickness: 1, color: Colors.grey[300]),

          // List Invoice
          filteredInvoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Icon(
                        Icons.search,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Tidak ditemukan invoice untuk Filter yang dipilih, \nmohon ganti filter untuk melihat lebih banyak data!',
                            ),
                            TextSpan(
                              text: ' \natau hapus filter klik disini',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          SalesHistoryPage(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : widget.isLoading
                  ? Expanded(
                      child: Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) => Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: const ListTile(
                              title: Text('Loading title'),
                              subtitle: Text('Loading subtitle'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Loading...'),
                                  SizedBox(height: 4),
                                  Text('Rp ...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          return Card(
                            color: _selectedInvoice == invoice
                                ? Colors.grey[200]
                                : null,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                invoice.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${invoice.customerName} - ${invoice.postingDate}',
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Status pembayaran (lunas atau belum lunas)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: invoice.docstatus == 1
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      invoice.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: invoice.docstatus == 1
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // Informasi mode pembayaran (kode Anda yang sudah ada)
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: invoice
                                              .mode_of_payment.isNotEmpty
                                          ? invoice.mode_of_payment
                                              .map((m) => Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        m.mode,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Rp ${NumberFormat('#,###').format(m.amount)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.green,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                                    ],
                                                  ))
                                              .toList()
                                          : [
                                              Text(
                                                'Tidak Diketahui',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              )
                                            ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (invoice.status == "Credit Note Issued") {
                                  // If the credit note callback is provided, use it
                                  if (widget.onCreditNoteInvoiceSelected !=
                                      null) {
                                    setState(() {
                                      _selectedInvoice = invoice;
                                    });
                                    widget
                                        .onCreditNoteInvoiceSelected!(invoice);
                                    widget.onInvoiceSelected(invoice);
                                  }
                                } else {
                                  setState(() {
                                    _selectedInvoice = invoice;
                                  });
                                  widget.onInvoiceSelected(invoice);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

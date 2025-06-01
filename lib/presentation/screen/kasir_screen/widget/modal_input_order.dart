import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:pos/presentation/screen/kasir_screen/kasir_screen_desktop.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CreateOrderModal extends StatefulWidget {
  const CreateOrderModal({Key? key}) : super(key: key);

  @override
  _CreateOrderModalState createState() => _CreateOrderModalState();
}

class _CreateOrderModalState extends State<CreateOrderModal> {
  // Color theme as specified
  final Color _primaryColor = const Color(0xFF533F77);

  // Selected invoice and item
  SalesInvoice? _selectedInvoice;
  SalesInvoiceItem? _selectedInvoiceItem;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<SalesInvoice> _salesInvoices = [];
  List<SalesInvoice> _filteredInvoices = [];

  bool _isLoading = false;
  String _searchQuery = '';

  Timer? _debounce;

  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final data = await SalesDataActions.getAllDatasDraft();

      setState(() {
        _salesInvoices = data;
        _applySearchFilter();
        _isLoading = false;

        // Select the first invoice if available
        if (_filteredInvoices.isNotEmpty) {
          _selectInvoice(_filteredInvoices[0]);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error fetching invoices: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load invoices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredInvoices = _salesInvoices;
    } else {
      _filteredInvoices = _salesInvoices.where((invoice) {
        // Search by invoice name/ID
        if (invoice.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return true;
        }

        // Search by customer name
        if (invoice.customerName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())) {
          return true;
        }

        // Search in items within invoice
        for (var item in invoice.items) {
          if ((item.itemName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())) ||
              (item.itemCode
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))) {
            return true;
          }
        }
        return false;
      }).toList();
    }
  }

  void _selectInvoice(SalesInvoice invoice) {
    setState(() {
      _selectedInvoice = invoice;

      // Select the first item by default
      if (_selectedInvoice!.items.isNotEmpty) {
        _selectedInvoiceItem = _selectedInvoice!.items[0];
      } else {
        _selectedInvoiceItem = null;
      }
    });
  }

  void _selectInvoiceItem(SalesInvoiceItem item) {
    setState(() {
      _selectedInvoiceItem = item;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 750), () {
      _handleSearch(query);
    });
  }

  Future<void> _handleSearch(String value) async {
    if (value.isNotEmpty && value.length < 4) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sales = await SalesDataActions.getDataSearchDraft(
          value.length < 4 ? 10 : 20, 0, value, '', '');
      if (mounted) {
        setState(() {
          _filteredInvoices = sales;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchInvoices(String query) {
    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
  }

  void _handleTagih() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    try {
      cartProvider.clearCart();

      Customer cust;

      cust = Customer(
          id: _selectedInvoice!.customer,
          code: _selectedInvoice!.customer,
          name: _selectedInvoice!.customerName,
          phone: _selectedInvoice!.customerPhone,
          address: _selectedInvoice!.customerAddress,
          uuid: _selectedInvoice!.customer);
      await customerProvider.saveCustomer(cust);

      if (_selectedInvoice != null && _selectedInvoiceItem != null) {
        List<CartItem> cartItems = _selectedInvoice!.items.map((item) {
          return CartItem(
            id: item.name,
            itemCode: item.itemCode,
            itemName: item.itemName,
            description: item.description,
            uom: item.stockUom,
            conversionFactor: 1, // Default or get this from somewhere
            qty: item.qty.toInt(),
            rate: item.rate.toInt(),
            amount: item.amount.toInt(),
            baseRate: item.priceListRate.toInt(),
            baseAmount: item.priceListRate.toInt() * item.qty.toInt(),
            priceListRate: item.priceListRate.toInt(),
            costCenter: '', // Default or get this from somewhere
            notes: '',
            discountValue: item.discountAmount > 0
                ? item.discountAmount
                : item.discountPercentage,
            isDiscountPercent:
                item.discountAmount == 0 && item.discountPercentage > 0,
          );
        }).toList();
        for (final item in cartItems!) {
          cartProvider.addToCart(item);
        }

        cartProvider.savePesanan(
            _selectedInvoice!.name,
            _selectedInvoice!.customerName,
            cartItems,
            _selectedInvoice!.customerAddress,
            _selectedInvoice!.customerPhone);
      }

      Navigator.pop(context);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              KasirScreenDesktop(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  String _formatDateTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Return false to prevent dialog dismissal when loading
          // Return true to allow dialog dismissal when not loading
          return !_isLoading;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                // Left Section: Invoices List - CHANGED TO CARD LIST
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search by Invoice Number',
                            labelStyle: TextStyle(color: _primaryColor),
                            prefixIcon:
                                Icon(Icons.search, color: _primaryColor),
                            border: _customOutlineInputBorder(),
                            focusedBorder:
                                _customOutlineInputBorder(isFocused: true),
                          ),
                          onChanged: (value) => _onSearchChanged(value),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _isLoading
                              ? Skeletonizer(
                                  enabled: true,
                                  child: ListView.builder(
                                    itemCount: 5,
                                    itemBuilder: (context, index) => Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: ListTile(
                                        title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 8),
                                              Text(
                                                'ID 123123123123123123',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _primaryColor,
                                                ),
                                              )
                                            ]),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 8),
                                            Text(
                                              'Customer Name',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _primaryColor,
                                              ),
                                            ),
                                            Text(
                                              'Posting Date',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _primaryColor,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Status',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _primaryColor,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                          ],
                                        ),
                                        trailing: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            SizedBox(height: 24),
                                            Text(
                                              'Status',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : _filteredInvoices.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No invoices available',
                                        style: TextStyle(color: _primaryColor),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _fetchInvoices,
                                      color: _primaryColor,
                                      child: ListView.builder(
                                        itemCount: _filteredInvoices.length,
                                        itemBuilder: (context, index) {
                                          final invoice =
                                              _filteredInvoices[index];
                                          final isSelected =
                                              _selectedInvoice?.name ==
                                                  invoice.name;
                                          final invoiceTotal =
                                              invoice.grandTotal;
                                          final formattedDate =
                                              _formatDateTime(invoice.creation);

                                          return Card(
                                            elevation: isSelected ? 3 : 1,
                                            color: isSelected
                                                ? Colors.grey.shade300
                                                : Colors.white,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  _selectInvoice(invoice),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'ID #${invoice.name}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                _primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Customer: ${invoice.customerName}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Items: ${invoice.items.length}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${_formatter.format(invoiceTotal)}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                _primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Section: Invoice Items - CHANGED TO REGULAR LIST
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _selectedInvoice == null
                        ? Center(
                            child: Text(
                              'Select an invoice to view items',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(_selectedInvoice!.creation),
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID #${_selectedInvoice!.name}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _primaryColor.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Customer: ${_selectedInvoice!.customerName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _primaryColor,
                                ),
                              ),
                              Text(
                                'Phone: ${_selectedInvoice!.customerPhone}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _primaryColor,
                                ),
                              ),
                              Text(
                                'Address: ${_selectedInvoice!.customerAddress}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _primaryColor,
                                ),
                              ),

                              const SizedBox(height: 16),
                              Text(
                                'Items:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // List of items in the invoice - CHANGED TO REGULAR LIST
                              Expanded(
                                child: _selectedInvoice!.items.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No items in this invoice',
                                          style:
                                              TextStyle(color: _primaryColor),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount:
                                            _selectedInvoice!.items.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                          color: _primaryColor.withOpacity(0.2),
                                          height: 1,
                                        ),
                                        itemBuilder: (context, index) {
                                          final item =
                                              _selectedInvoice!.items[index];

                                          // Calculate if there's a discount
                                          final hasDiscount =
                                              item.discountPercentage > 0 ||
                                                  item.discountAmount > 0;
                                          final originalAmount =
                                              item.priceListRate * item.qty;

                                          return ListTile(
                                            title: Text(
                                              item.itemName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: _primaryColor,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '${item.qty} ${item.stockUom} x ${_formatter.format(item.rate)}'),
                                                if (hasDiscount)
                                                  Text(
                                                    item.discountPercentage > 0
                                                        ? 'Discount: ${item.discountPercentage}%'
                                                        : 'Discount: ${_formatter.format(item.discountAmount)}',
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 250, 85, 73),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (hasDiscount)
                                                  Text(
                                                    '${_formatter.format(originalAmount)}',
                                                    style: TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      fontSize: 10,
                                                      color: _primaryColor,
                                                    ),
                                                  ),
                                                Text(
                                                  '${_formatter.format(item.amount)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: _primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              // Total amount
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total: ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    Text(
                                      '${_formatter.format(_selectedInvoice!.grandTotal)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Create Order button
                              Row(
                                children: [
                                  // Delete Invoice Button
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red[700]!,
                                            Colors.red[500]!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ||
                                                _selectedInvoice == null
                                            ? null
                                            : () => _showDeleteConfirmation(
                                                context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Delete Invoice',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 12), // Spasi antara tombol

                                  // Create Invoice Button (your existing button)
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _primaryColor,
                                            _primaryColor.withOpacity(0.7)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ||
                                                _selectedInvoice == null
                                            ? null
                                            : _handleTagih,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Create Invoice',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
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
          ),
        ));
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          // Mengatur lebar maksimal dialog
          child: Container(
            width: 300, // Lebar yang lebih kecil
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red[700], size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Konfirmasi Hapus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Apakah Anda yakin ingin menghapus invoice ini?',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Invoice No: ${_selectedInvoice?.name ?? ""}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _handleDeleteInvoice();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    );
  }

// Function untuk menangani delete invoice
  Future<void> _handleDeleteInvoice() async {
    // Implementasikan logika delete invoice di sini
    print('Menghapus invoice: ${_selectedInvoice?.name}');
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final response =
        await SalesDataActions.deleteSalesInvoice(_selectedInvoice!.name);

    if (response) {
      // Tampilkan notifikasi error

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      Navigator.of(context).pop();

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice berhasil dihapus'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus invoice'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  }

  // Custom method for creating consistent OutlineInputBorder
  OutlineInputBorder _customOutlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isFocused ? _primaryColor : Colors.grey.shade400,
        width: isFocused ? 2 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pos/core/providers/mode_of_payment.dart';
import 'package:pos/core/action/payment_entry_action/payment_entry_action.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos/core/action/customer/customer_actions.dart';
import 'package:pos/core/action/sales_invoice_action/sales_invoice_action.dart';
import 'package:pos/core/providers/customer_provider.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/data/models/sales_invoice/sales_invoice.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/theme/app_colors.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/kasbon_customer_list_section.dart';
import 'package:pos/presentation/screen/kasir_screen/widget/kasbon_payment_section.dart';

final _formatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

class ModalKasbon extends StatefulWidget {
  const ModalKasbon({Key? key}) : super(key: key);

  @override
  _ModalKasbonState createState() => _ModalKasbonState();
}

class _ModalKasbonState extends State<ModalKasbon> {
  final PaymentEntryAction _paymentAction = PaymentEntryAction();

  // Data structures
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<SalesInvoice> _salesInvoices = [];
  List<SalesInvoice> _selectedInvoices = [];
  double _totalAmount = 0;
  double _kembalian = 0;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  String _selectedPaymentMode = 'TUNAI';
  List<String> _paymentModes = ['TUNAI'];

  // Search functionality
  Timer? _debounce;
  bool _isLoading = false;
  bool _searchByPhone = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadModeOfPayment();
    _paymentController.addListener(_calculateKembalian);
  }

  void _loadModeOfPayment() async {
    final provider = Provider.of<ModeOfPaymentProvider>(context, listen: false);
    final payments = provider.modeOfPayments;

    setState(() {
      _paymentModes = payments.isNotEmpty
          ? payments
              .where((payment) => payment.modeOfPayment != 'KASBON')
              .map((payment) => payment.modeOfPayment)
              .toList()
          : ["TUNAI"];

      _selectedPaymentMode = _paymentModes.contains(_selectedPaymentMode)
          ? _selectedPaymentMode
          : _paymentModes.first;
    });
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await CustomerActions.getCustomers(10, 0, '');
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error loading customers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _searchCustomers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 750), () {
      _handleSearch(query);
    });
  }

  Future<void> _handleSearch(String query) async {
    if (query.isNotEmpty && query.length < 4) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final customers = await CustomerActions.getCustomers(
        query.length < 4 ? 10 : 20,
        0,
        query,
        searchByPhone: _searchByPhone,
      );
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error searching customers: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSalesInvoices(String customerId) async {
    setState(() => _isLoading = true);
    try {
      final sales = await SalesDataActions.getDataUnpaid(customerId);
      setState(() {
        _salesInvoices = sales;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error fetching invoices: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _selectedInvoices.clear();
    });
    _fetchSalesInvoices(customer.code ?? '');
  }

  void _selectInvoice(SalesInvoice invoice, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedInvoices.add(invoice);
      } else {
        _selectedInvoices.remove(invoice);
      }
      _totalAmount =
          _selectedInvoices.fold(0, (sum, inv) => sum + inv.grandTotal);
      _calculateKembalian();
    });
  }

  void _calculateKembalian() {
    if (_paymentController.text.isEmpty) {
      setState(() => _kembalian = 0);
      return;
    }

    if (_selectedPaymentMode == 'TUNAI') {
      // Remove currency symbol, separators and parse the payment amount
      final paymentText = _paymentController.text
          .replaceAll(_formatter.currencySymbol, '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();

      final payment = double.tryParse(paymentText) ?? 0;
      setState(() {
        _kembalian = payment - _totalAmount;
      });
    } else {
      setState(() => _kembalian = 0);
    }
  }

  bool _canProcessPayment() {
    if (_selectedInvoices.isEmpty) return false;

    if (_selectedPaymentMode == 'TUNAI') {
      if (_paymentController.text.isEmpty) return false;

      final payment = double.tryParse(_paymentController.text
              .replaceAll(_formatter.currencySymbol, '')
              .replaceAll('.', '')
              .replaceAll(',', '')
              .trim()) ??
          0;
      return payment >= _totalAmount;
    } else {
      return true;
    }
  }

  Future<void> _processPayment() async {
    if (!_canProcessPayment()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _paymentAction.processMultiplePayments(
        salesInvoices: _selectedInvoices,
        modeOfPayment: _selectedPaymentMode,
      );

      Navigator.pop(context); // Close kasbon modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paymentController.dispose();
    _referenceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  CustomerListSection(
                    customers: _customers,
                    selectedCustomer: _selectedCustomer,
                    isLoading: _isLoading,
                    searchController: _searchController,
                    searchByPhone: _searchByPhone,
                    onSearch: _searchCustomers,
                    onSelectCustomer: _selectCustomer,
                    onToggleSearchMode: (value) {
                      setState(() {
                        _searchByPhone = value;
                        if (_searchController.text.isNotEmpty) {
                          _searchCustomers(_searchController.text);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.surface,
                      child: _selectedCustomer == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Select a customer to view invoices',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 14, 24, 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.accent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedCustomer!.name ?? '',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            if (_selectedCustomer!
                                                    .phone?.isNotEmpty ??
                                                false) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedCustomer!.phone ?? '',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _isLoading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.accent,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : _salesInvoices.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.receipt_long,
                                                    size: 64,
                                                    color: AppColors
                                                        .textSecondary
                                                        .withOpacity(0.3),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Text(
                                                    'No unpaid invoices found',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Unpaid Invoices',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              ListView.builder(
                                                            itemCount:
                                                                _salesInvoices
                                                                    .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              final invoice =
                                                                  _salesInvoices[
                                                                      index];
                                                              final isSelected =
                                                                  _selectedInvoices
                                                                      .contains(
                                                                          invoice);

                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: AppColors
                                                                      .surface,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              16),
                                                                  border: Border
                                                                      .all(
                                                                    color: isSelected
                                                                        ? AppColors
                                                                            .accent
                                                                        : AppColors
                                                                            .border,
                                                                    width: 1.5,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: isSelected
                                                                          ? AppColors.accent.withOpacity(
                                                                              0.1)
                                                                          : Colors
                                                                              .black
                                                                              .withOpacity(0.02),
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          const Offset(
                                                                              0,
                                                                              2),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child:
                                                                    CheckboxListTile(
                                                                  value:
                                                                      isSelected,
                                                                  onChanged: (value) =>
                                                                      _selectInvoice(
                                                                          invoice,
                                                                          value),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            16),
                                                                  ),
                                                                  title: Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          invoice
                                                                              .name,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                AppColors.textPrimary,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        padding:
                                                                            const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              12,
                                                                          vertical:
                                                                              6,
                                                                        ),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: isSelected
                                                                              ? AppColors.accent.withOpacity(0.1)
                                                                              : Colors.green.shade50,
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          _formatter
                                                                              .format(invoice.grandTotal),
                                                                          style:
                                                                              TextStyle(
                                                                            color: isSelected
                                                                                ? AppColors.accent
                                                                                : Colors.green.shade700,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontSize:
                                                                                14,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  activeColor:
                                                                      AppColors
                                                                          .accent,
                                                                  checkColor:
                                                                      Colors
                                                                          .white,
                                                                  contentPadding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        if (_selectedInvoices
                                                            .isNotEmpty)
                                                          PaymentSection(
                                                            totalAmount:
                                                                _totalAmount,
                                                            kembalian:
                                                                _kembalian,
                                                            selectedPaymentMode:
                                                                _selectedPaymentMode,
                                                            paymentModes:
                                                                _paymentModes,
                                                            paymentController:
                                                                _paymentController,
                                                            referenceController:
                                                                _referenceController,
                                                            onPaymentModeChanged:
                                                                (value) {
                                                              if (value !=
                                                                  null) {
                                                                setState(() {
                                                                  _selectedPaymentMode =
                                                                      value;
                                                                  if (value !=
                                                                      'TUNAI') {
                                                                    _paymentController
                                                                            .text =
                                                                        _totalAmount
                                                                            .toString();
                                                                  } else {
                                                                    _paymentController
                                                                        .text = '';
                                                                  }
                                                                });
                                                              }
                                                            },
                                                            onProcessPayment:
                                                                _processPayment,
                                                            canProcessPayment:
                                                                _canProcessPayment(),
                                                            formatter:
                                                                _formatter,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

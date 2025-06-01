import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:pos/data/database/database_helper.dart';
import 'package:pos/data/api/api_service.dart';

class TransactionController extends ChangeNotifier {
  // State variables
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _rawInvoices = []; // Store raw invoices data
  List<Map<String, dynamic>> _processedTransactions =
      []; // Store processed data
  bool isLoading1 = false;
  String _searchQuery = '';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Timer? _debounce;
  // Add payment method selection
  String _selectedPaymentMethod = 'Semua';

  // Flag untuk API atau local DB
  final bool _useApi = true;

  // Payment method options
  final List<String> paymentMethods = ['Semua', 'Tunai', 'Debit', 'QRIS'];

  // Getters
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => isLoading1;
  String get searchQuery => _searchQuery;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  // Add getter for payment method
  String get selectedPaymentMethod => _selectedPaymentMethod;

  // Constructor untuk mengatur tanggal default ke hari ini
  TransactionController() {
    // Set default tanggal ke hari ini
    _setDefaultDateToToday();
  }

  // Fungsi untuk mengatur tanggal default ke hari ini
  void _setDefaultDateToToday() {
    final today = DateTime.now();
    _selectedStartDate =
        DateTime(today.year, today.month, today.day); // awal hari ini
    _selectedEndDate = DateTime(
        today.year, today.month, today.day, 23, 59, 59); // akhir hari ini
  }

  // Methods
  bool hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedStartDate != null ||
        _selectedEndDate != null ||
        _selectedPaymentMethod != 'Semua';
  }

  void setSearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      notifyListeners();
      applyFilters(); // Apply filters after debounce
    });
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _selectedStartDate = start;
    _selectedEndDate = end;
    notifyListeners();
    applyFilters();
  }

  // Add method to set payment method
  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
    applyFilters();
  }

  void clearFilters() {
    _setDefaultDateToToday(); // Reset ke tanggal hari ini, bukan null
    _searchQuery = '';
    _selectedPaymentMethod = 'Semua';
    refreshTransactions();
    notifyListeners();
  }

  // Reset filter ke tanggal null (semua tanggal) jika perlu
  void resetDateFilters() {
    _selectedStartDate = null;
    _selectedEndDate = null;
    notifyListeners();
    applyFilters();
  }

  // New method to refresh transactions without reloading from API
  void refreshTransactions() {
    if (_processedTransactions.isNotEmpty) {
      // Reset to the full processed dataset
      _transactions = List.from(_processedTransactions);
      applyFilters();
    } else {
      // If no processed data yet, load from API
      loadTransactions();
    }
  }

  String getActiveFiltersText() {
    List<String> filters = [];

    if (_searchQuery.isNotEmpty) {
      filters.add("ID: $_searchQuery");
      // Tidak menambahkan filter tanggal jika pencarian aktif
    } else if (_selectedStartDate != null && _selectedEndDate != null) {
      // Cek apakah range tanggal adalah hari ini
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      if (_isSameDay(_selectedStartDate!, startOfToday) &&
          _isSameDay(_selectedEndDate!, endOfToday)) {
        filters.add("Tanggal: Hari Ini");
      } else {
        filters.add("Tanggal: ${getFormattedDateRange()}");
      }
    }

    if (_selectedPaymentMethod != 'Semua') {
      filters.add("Pembayaran: $_selectedPaymentMethod");
    }

    return filters.isEmpty ? '' : 'Filter aktif: ${filters.join(" | ")}';
  }

  // Helper untuk membandingkan apakah dua tanggal adalah hari yang sama
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String getFormattedDateRange() {
    if (_selectedStartDate == null || _selectedEndDate == null) return '';
    final formatter = DateFormat('dd MMM yyyy');
    return "${formatter.format(_selectedStartDate!)} - ${formatter.format(_selectedEndDate!)}";
  }

  String getEmptyMessage() {
    List<String> filters = [];
    if (_searchQuery.isNotEmpty) {
      filters.add('ID "$_searchQuery"');
      // Tidak menambahkan filter tanggal jika pencarian aktif
    } else if (_selectedStartDate != null && _selectedEndDate != null) {
      // Cek apakah range tanggal adalah hari ini
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      if (_isSameDay(_selectedStartDate!, startOfToday) &&
          _isSameDay(_selectedEndDate!, endOfToday)) {
        filters.add('hari ini');
      } else {
        filters.add('rentang tanggal tersebut');
      }
    }
    if (_selectedPaymentMethod != 'Semua') {
      filters.add('pembayaran $_selectedPaymentMethod');
    }
    if (filters.isEmpty) {
      return 'Tidak ada transaksi';
    } else if (filters.length == 1) {
      return 'Tidak ada transaksi dengan ${filters[0]}';
    } else {
      return 'Tidak ada transaksi dengan ${filters.join(' dan ')}';
    }
  }

  // Memisahkan fungsi untuk loading data dan filtering
  Future<void> loadTransactions() async {
    // Mulai proses loading
    isLoading1 = true;
    notifyListeners();

    try {
      // Hanya ambil data mentah, tanpa filter
      _rawInvoices = await fetchSalesInvoices();

      // Proses data mentah menjadi format transaksi
      final processedTransactions = await _processInvoices(_rawInvoices);

      // Simpan data asli yang sudah diproses
      _processedTransactions = List.from(processedTransactions);
      _transactions = List.from(processedTransactions);

      // Terapkan filter setelah data selesai diproses
      applyFilters();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      isLoading1 = false; // Selesai loading
      notifyListeners();
    }
  }

  // Fungsi untuk menerapkan filter pada data yang sudah ada
  // Modifikasi fungsi applyFilters di TransactionController
  void applyFilters() {
    if (_processedTransactions.isEmpty) {
      // Jika belum ada data, load dulu
      if (!isLoading1) loadTransactions();
      return;
    }

    // Mulai dengan data lengkap
    List<Map<String, dynamic>> filteredData = List.from(_processedTransactions);

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      filteredData = filteredData.where((transaction) {
        final transactionId = transaction['transactionId'] ?? '';
        return transactionId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      // Penting: Jika ada pencarian aktif, SKIP filter tanggal
      // sehingga hasil pencarian bisa dari tanggal kapan saja
    }
    // Filter berdasarkan tanggal HANYA jika tidak ada pencarian aktif
    else if (_selectedStartDate != null && _selectedEndDate != null) {
      filteredData = filteredData.where((transaction) {
        try {
          final transactionDate =
              DateFormat('dd MMM yyyy').parse(transaction['transactionDate']);
          return transactionDate.isAfter(
                  _selectedStartDate!.subtract(const Duration(days: 1))) &&
              transactionDate
                  .isBefore(_selectedEndDate!.add(const Duration(days: 1)));
        } catch (e) {
          print('Error parsing date: $e');
          return false;
        }
      }).toList();
    }

    // Filter berdasarkan metode pembayaran
    if (_selectedPaymentMethod != 'Semua') {
      filteredData = filteredData.where((transaction) {
        return transaction['paymentMethod'] == _selectedPaymentMethod;
      }).toList();
    }

    // Update state dengan hasil filter
    _transactions = filteredData;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchSalesInvoices() async {
    final startTime = DateTime.now();
    print('Start fetching sales invoices at: $startTime');

    try {
      final invoices = await ApiService.getSalesInvoices();

      final endTime = DateTime.now();
      print('Finished fetching sales invoices at: $endTime');
      print(
          'Total fetching duration: ${endTime.difference(startTime).inMilliseconds} ms');

      return invoices;
    } catch (e) {
      final endTime = DateTime.now();
      print('Error fetching sales invoices at: $endTime');
      print(
          'Total duration (including error): ${endTime.difference(startTime).inMilliseconds} ms');

      throw Exception('Failed to fetch sales invoices: $e');
    }
  }

  // Process invoices without applying filters
  Future<List<Map<String, dynamic>>> _processInvoices(
      List<Map<String, dynamic>> invoices) async {
    // Proses semua data sekaligus secara paralel
    final futures = invoices.map((invoice) async {
      final invoiceId = invoice['name'];
      try {
        final detailData = await ApiService.getSalesInvoiceDetail(invoiceId);
        final transaction = ApiService.convertToTransactionFormat(detailData);
        return transaction;
      } catch (e) {
        print('Error fetching details for invoice $invoiceId: $e');
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);
    return results
        .where((result) => result != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // Get detail of a specific transaction
  Future<Map<String, dynamic>?> getTransactionDetail(
      String transactionId) async {
    try {
      Map<String, dynamic>? transactionData;
      List<Map<String, dynamic>> orderItems = [];

      if (_useApi) {
        final invoiceDetail =
            await ApiService.getSalesInvoiceDetail(transactionId);
        transactionData = ApiService.convertToTransactionFormat(invoiceDetail);
        orderItems = ApiService.convertToOrderItems(invoiceDetail);
      } else {
        transactionData =
            await DatabaseHelper.instance.getTransactionDetails(transactionId);
        orderItems = await DatabaseHelper.instance.getOrderItems(transactionId);
      }

      if (transactionData == null) {
        return null;
      }

      return {
        'transaction': transactionData,
        'orderItems': orderItems,
      };
    } catch (e) {
      throw Exception('Failed to load transaction details: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

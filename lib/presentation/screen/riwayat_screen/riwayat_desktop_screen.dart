import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'components/Transaction_Detail_Widget.dart';
import 'components/Transaction_Filter_Widget.dart';
import 'components/Transaction_List_Widget.dart';
import 'components/transaction_controller.dart';

class RiwayatDesktopScreen extends StatefulWidget {
  const RiwayatDesktopScreen({super.key});

  @override
  _RiwayatDesktopScreenState createState() => _RiwayatDesktopScreenState();
}

class _RiwayatDesktopScreenState extends State<RiwayatDesktopScreen> {
  final TransactionController _controller = TransactionController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _selectedTransactionId;
  Map<String, dynamic>? _selectedTransaction;
  List<Map<String, dynamic>>? _selectedOrderItems;
  bool _isDetailLoading = false;

  @override
  void initState() {
    super.initState();
    // Load data after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _controller.clearFilters();
      _isSearching = false;
    });
  }

  // Fungsi untuk melihat semua transaksi (tanpa filter tanggal)
  void _showAllTransactions() {
    setState(() {
      _controller.resetDateFilters(); // Fungsi untuk menghapus filter tanggal
      _controller.refreshTransactions();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _controller.setSearchQuery('');
        _controller.refreshTransactions();

        // Jika ingin menghapus semua filter saat keluar dari pencarian
        _controller.clearFilters();
      }
    });
  }

  void _loadTransactionDetail(BuildContext context, String transactionId) async {
    setState(() {
      _isDetailLoading = true;
      _selectedTransactionId = transactionId;
      _selectedTransaction = null;
      _selectedOrderItems = null;
    });

    try {
      final transactionData = await _controller.getTransactionDetail(transactionId);

      if (transactionData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi tidak ditemukan')),
          );
        }
        setState(() {
          _isDetailLoading = false;
        });
        return;
      }

      setState(() {
        _selectedTransaction = transactionData['transaction'];
        _selectedOrderItems = transactionData['orderItems'];
        _isDetailLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDetailLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaction details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari ID Transaksi',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
          style: const TextStyle(color: Colors.black),
          autofocus: true,
          onChanged: (query) => _controller.setSearchQuery(query),
        )
            : const Text('Riwayat'),
        centerTitle: !_isSearching,
        actions: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSearch,
                tooltip: 'Close Search',
                padding: const EdgeInsets.all(8.0),
              ),
            ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearch,
                tooltip: 'Search',
                padding: const EdgeInsets.all(8.0),
              ),
            ),
          if (_controller.hasActiveFilters() && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearFilters,
                tooltip: 'Clear Filters',
                padding: const EdgeInsets.all(8.0),
              ),
            ),
        ],
      ),
      drawer: const SidebarMenu(),
      body: Row(
        children: [
          // Left side - Transaction List
          Expanded(
            flex: 3, // Mengatur proporsi layar (3/5 untuk list transaksi)
            child: Column(
              children: [
                // Hanya tampilkan filter jika tidak dalam mode pencarian
                if (!_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Column(
                          children: [
                            TransactionFilterWidget(
                              selectedPaymentMethod: _controller.selectedPaymentMethod,
                              onPaymentMethodChanged: (method) {
                                _controller.setPaymentMethod(method);
                              },
                              selectedStartDate: _controller.selectedStartDate,
                              selectedEndDate: _controller.selectedEndDate,
                              onDateRangeSelected: (start, end) {
                                _controller.setDateRange(start, end);
                              },
                            ),
                            // Tampilkan tombol "Lihat Semua" jika saat ini menampilkan transaksi dengan filter tanggal
                            if (_controller.selectedStartDate != null && _controller.selectedEndDate != null)
                              TextButton(
                                onPressed: _showAllTransactions,
                                child: const Text('Lihat Semua Transaksi'),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                // Informasi filter aktif, juga hanya jika tidak dalam mode pencarian
                if (_controller.hasActiveFilters() && !_isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    width: double.infinity,
                    child: Text(
                      _controller.getActiveFiltersText(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Divider hanya jika ada filter yang ditampilkan
                if (!_isSearching)
                  const Divider(height: 1, thickness: 0.5),

                // List transaksi
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return TransactionListWidget(
                          transactions: _controller.transactions,
                          searchQuery: _controller.searchQuery,
                          isLoading: _controller.isLoading,
                          buildEmptyMessage: () => _controller.getEmptyMessage(),
                          onTransactionTap: (ctx, transactionId) =>
                              _loadTransactionDetail(ctx, transactionId),
                          selectedTransactionId: _selectedTransactionId,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vertical divider
          const VerticalDivider(width: 1, thickness: 0.5),

          // Right side - Transaction Detail
          Expanded(
            flex: 2, // Mengatur proporsi layar (2/5 untuk detail transaksi)
            child: _selectedTransactionId == null
                ? const Center(
              child: Text('Pilih transaksi untuk melihat detail'),
            )
                : _isDetailLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTransaction != null && _selectedOrderItems != null
                ? TransactionDetailWidget(
              transaction: _selectedTransaction!,
              orderItems: _selectedOrderItems!,
            )
                : const Center(
              child: Text('Data transaksi tidak tersedia'),
            ),
          ),
        ],
      ),
    );
  }
}
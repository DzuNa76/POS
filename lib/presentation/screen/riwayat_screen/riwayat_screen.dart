import 'package:flutter/material.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'components/Transaction_Detail_Bottom_Sheet.dart';
import 'components/Transaction_Filter_Widget.dart';
import 'components/Transaction_List_Widget.dart';
import 'components/transaction_controller.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  _RiwayatScreenState createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TransactionController _controller = TransactionController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _selectedTransactionId;


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
      _controller.clearFilters(); // Ini akan menyetel tanggal ke hari ini
      _isSearching = false;
    });
  }

  // Fungsi untuk melihat semua transaksi (tanpa filter tanggal)
  void _showAllTransactions() {
    setState(() {
      _controller.resetDateFilters(); // Fungsi baru untuk menghapus filter tanggal
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
      }
    });
  }

  void _showTransactionDetail(
      BuildContext context, String transactionId) async {
    setState(() {
      _selectedTransactionId = transactionId;
    });

    // For desktop layout, we just select the transaction
    // For mobile layout, we show the bottom sheet
    final width = MediaQuery.of(context).size.width;
    if (width <= 900) {
      await _showTransactionDetailBottomSheet(context, transactionId);
    }
    // In desktop mode, details will be shown in the side panel
  }

  Future<void> _showTransactionDetailBottomSheet(
      BuildContext context, String transactionId) async {
    // Tampilkan indikator loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactionData =
      await _controller.getTransactionDetail(transactionId);

      if (context.mounted) Navigator.pop(context);

      if (transactionData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi tidak ditemukan')),
          );
        }
        return;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return TransactionDetailBottomSheet(
              transaction: transactionData['transaction'],
              orderItems: transactionData['orderItems'],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaction details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari ID Transaksi',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
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
                      _showTransactionDetail(ctx, transactionId),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    // Desktop layout with side-by-side list and details
    return Row(
      children: [
        // Left panel: Filters and Transaction List (1/3 of the screen)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Filter widgets
              if (!_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                        ],
                      );
                    },
                  ),
                ),

              // Active filters text
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

              if (!_isSearching)
                const Divider(height: 1, thickness: 0.5),

              // Transaction list
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
                            _showTransactionDetail(ctx, transactionId),
                        selectedTransactionId: _selectedTransactionId,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vertical divider between panels
        const VerticalDivider(width: 1, thickness: 0.5),

        // Right panel: Transaction Details (2/3 of the screen)
        Expanded(
          flex: 2,
          child: _selectedTransactionId == null
              ? const Center(
            child: Text('Pilih transaksi untuk melihat detail'),
          )
              : FutureBuilder(
            future: _controller.getTransactionDetail(_selectedTransactionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text('Transaksi tidak ditemukan'),
                );
              }

              final transactionData = snapshot.data as Map<String, dynamic>;

              // Gunakan TransactionDetailBottomSheet dalam Card agar terlihat baik di desktop
              return Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 2,
                child: SingleChildScrollView(
                  child: TransactionDetailBottomSheet(
                    transaction: transactionData['transaction'],
                    orderItems: transactionData['orderItems'],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildTransactionDetailCard(Map<String, dynamic> transactionData) {
  //   final transaction = transactionData['transaction'];
  //   final orderItems = transactionData['orderItems'];
  //
  //   return Card(
  //     elevation: 2,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Transaction header information
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Tanggal: ${transaction['transactionDate']?.toString() ?? ''}',
  //                 style: const TextStyle(fontSize: 16),
  //               ),
  //               _getPaymentMethodChip(transaction['paymentMethod'] ?? 'Lainnya'),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //
  //           // Customer information
  //           Text('Pelanggan: ${transaction['customerName']?.toString() ?? ''}'),
  //           const SizedBox(height: 24),
  //
  //           // Order items
  //           const Text(
  //             'Daftar Item',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 8),
  //           // Item list
  //           if (orderItems != null && orderItems.isNotEmpty)
  //             ListView.builder(
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               itemCount: orderItems.length,
  //               itemBuilder: (context, index) {
  //                 final item = orderItems[index];
  //                 return ListTile(
  //                   title: Text(item['productName']?.toString() ?? ''),
  //                   subtitle: Text('${item['quantity'] ?? 0} x Rp ${item['price']?.toString() ?? '0'}'),
  //                   trailing: Text('Rp ${item['subtotal']?.toString() ?? '0'}'),
  //                 );
  //               },
  //             ),
  //
  //           const Divider(),
  //
  //           // Total
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               const Text(
  //                 'Total',
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //               Text(
  //                 'Rp ${transaction['total']?.toString() ?? '0'}',
  //                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _getPaymentMethodChip(String paymentMethod) {
    Color chipColor;
    IconData iconData;

    switch (paymentMethod) {
      case 'Tunai':
        chipColor = Colors.green;
        iconData = Icons.money;
        break;
      case 'Debit':
        chipColor = Colors.blue;
        iconData = Icons.credit_card;
        break;
      case 'QRIS':
        chipColor = Colors.purple;
        iconData = Icons.qr_code;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.receipt;
    }

    return Chip(
      backgroundColor: chipColor.withOpacity(0.1),
      side: BorderSide(color: chipColor),
      label: Text(paymentMethod),
      avatar: Icon(iconData, color: chipColor, size: 16),
    );
  }
}
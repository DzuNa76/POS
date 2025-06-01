import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/api/api_service.dart';
import 'package:pos/data/api/dio_client.dart';
import 'package:pos/data/database/database_page_helper.dart';
import 'package:pos/data/repositories/item_repository.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/core/providers/preference_helper.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/core/providers/voucher_provider.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/product_list.dart';
import 'package:pos/presentation/widgets/widgets.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:provider/provider.dart';

class KasirScreenMobile extends StatefulWidget {
  const KasirScreenMobile({super.key});

  @override
  _KasirScreenMobileState createState() => _KasirScreenMobileState();
}

class _KasirScreenMobileState extends State<KasirScreenMobile> {
  String _searchQuery = ""; // State untuk query pencarian
  bool _isSyncing = false; // State untuk status sinkronisasi
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final isGrid = await PreferenceHelper.getViewMode();
    setState(() {
      _isGridView = isGrid;
    });
  }

  Future<void> _toggleViewMode() async {
    final newMode = !_isGridView;
    await PreferenceHelper.saveViewMode(newMode);
    setState(() {
      _isGridView = newMode;
    });
  }

  void showVoucherModal(BuildContext context) {
    final voucherProvider =
        Provider.of<VoucherProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Voucher',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: voucherProvider.availableVouchers.map((voucher) {
                    return ListTile(
                      leading:
                          const Icon(Icons.card_giftcard, color: Colors.blue),
                      title: Text(
                        voucher.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        voucher.isGlobal
                            ? "Diskon ${voucher.discount}% untuk seluruh pesanan"
                            : "Diskon Rp ${voucher.discount} untuk item tertentu",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      onTap: () {
                        voucherProvider.selectVoucher(voucher);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderSummaryScreenMobile()),
    );
  }

  Future<void> syncData(BuildContext context) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    setState(() {
      _isSyncing = true;
    });

    try {
      await productProvider.fetchItemsWithProgress(
        batchSize: 500,
        onProgressUpdate: (loaded) {
          if (!mounted) return;
          debugPrint('Loaded items: $loaded');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disinkronkan!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    int totalItems = cartProvider.totalItems;
    double totalPrice = cartProvider.totalPrice.toDouble();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _isSyncing
                      ? const Icon(Icons.refresh,
                          key: ValueKey('syncing'), color: Colors.grey)
                      : const Icon(Icons.refresh_outlined,
                          key: ValueKey('default'), color: Colors.black),
                ),
                onPressed: _isSyncing ? null : () => syncData(context),
              ),
              if (_isSyncing) // Menampilkan teks Sync saat proses sinkronisasi
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sync...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              if (_isSyncing) // Menampilkan animasi loading
                const Positioned(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const SidebarMenu(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBarCashier(
              onSearch: Provider.of<ProductProvider>(context, listen: false)
                  .searchItem,
            ),
            const SizedBox(height: 10),
            ProductCategories(),
            const SizedBox(height: 10),
            Expanded(
              child: _isGridView
                  ? ProductGrid() // Tampilan Grid
                  : ProductList(), // Tampilan List
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -1),
                blurRadius: 3,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: totalItems > 0
                ? () => navigateToCheckout(context)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tidak ada item di keranjang')),
                    );
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: totalItems > 0 ? Colors.green : Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: totalItems > 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
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
                      Text(
                        '${formatter.format(totalPrice)} ->',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Tambahkan Item....',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

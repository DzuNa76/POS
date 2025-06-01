import 'package:flutter/material.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/product_card.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/data/models/item_model.dart';
import 'product_detail_dialog.dart';
import 'sync_indicator.dart';
import 'package:intl/intl.dart';

class ProductList extends StatefulWidget {
  const ProductList({Key? key}) : super(key: key);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController scrollController = ScrollController();
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeProductData();
    _setupScrollListener();
  }

  void _initializeProductData() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await productProvider.loadLocalItems();

      // If there are no local items, load initial items
      if (productProvider.filteredItems.isEmpty) {
        await productProvider.loadItems();
      }

      // Start background sync after initial data is loaded
      _startBackgroundSync();
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        // Load more data when reaching bottom
        Provider.of<ProductProvider>(context, listen: false).loadItems();
      }
    });
  }

  Future<void> _startBackgroundSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      await productProvider.fetchItemsWithProgress(
        batchSize: 500,
        onProgressUpdate: (loaded) {
          if (!mounted) return;

          setState(() {});
        },
      );

      // Notification when complete
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data item berhasil di-update!')),
        );
      }
    } catch (e) {
      debugPrint('Error background sync: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showItemDetail(Item item) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: productProvider.filteredItems.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: productProvider.filteredItems.length +
                          (productProvider.isLoading ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const Divider(thickness: 1.5, color: Colors.grey),
                      itemBuilder: (context, index) {
                        if (index >= productProvider.filteredItems.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final item = productProvider.filteredItems[index];

                        return GestureDetector(
                          onTap: () => _showItemDetail(item),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(item.standardRate ?? 0),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Stok: ${item.totalProjectedQty?.toStringAsFixed(0) ?? '-'}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                if ((item.maxDiscount ?? 0) > 0)
                                  Text(
                                    "Diskon: ${item.maxDiscount?.toStringAsFixed(2)}%",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.itemGroup ??
                                        'Kategori Tidak Diketahui',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        // Sync progress indicator in bottom right corner
        if (productProvider.isSyncing)
          SyncIndicator(
            currentBatch: productProvider.currentBatch,
            loadedItems: productProvider.loadedItems,
            savedItems: productProvider.savedItems,
          ),
      ],
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

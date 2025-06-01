// lib/presentation/widgets/product_grid/product_grid.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/data/models/item_model.dart';
import 'product_card.dart';
import 'product_detail_dialog.dart';
import 'sync_indicator.dart';

class ProductGrid extends StatefulWidget {
  const ProductGrid({Key? key}) : super(key: key);

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final ScrollController scrollController = ScrollController();
  int _loadedItems = 0;
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
        // Load lebih banyak data jika mencapai batas bawah scroll
        Provider.of<ProductProvider>(context, listen: false).loadItems();
      }
    });
  }

  Future<void> _startBackgroundSync() async {
    if (!mounted) return; // Periksa mounted sebelum memulai

    setState(() {
      _isSyncing = true;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      await productProvider.fetchItemsWithProgress(
        batchSize: 500,
        onProgressUpdate: (loaded) {
          if (!mounted) return; // Periksa mounted dalam callback
          setState(() {
            _loadedItems = loaded;
          });
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
    final gridSettings = _getResponsiveGridSettings(context);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: productProvider.filteredItems.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSettings.crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: gridSettings.childAspectRatio,
                      ),
                      itemCount: productProvider.filteredItems.length +
                          (productProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= productProvider.filteredItems.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final item = productProvider.filteredItems[index];

                        return ProductCard(
                          item: item,
                          onTap: () => _showItemDetail(item),
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

  GridSettings _getResponsiveGridSettings(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Determine number of columns based on screen width
    if (screenWidth >= 1200) {
      return GridSettings(
          crossAxisCount: 6, childAspectRatio: 3 / 4); // Desktop
    } else if (screenWidth >= 900) {
      return GridSettings(
          crossAxisCount: 4, childAspectRatio: 4 / 5); // Tablet landscape
    } else if (screenWidth >= 600) {
      return GridSettings(
          crossAxisCount: 2, childAspectRatio: 4 / 5); // Tablet portrait
    } else {
      return GridSettings(crossAxisCount: 1, childAspectRatio: 4 / 2); // Mobile
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class GridSettings {
  final int crossAxisCount;
  final double childAspectRatio;

  GridSettings({
    required this.crossAxisCount,
    required this.childAspectRatio,
  });
}

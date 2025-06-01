import 'package:flutter/material.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/core/providers/product_provider.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/product_detail_dialog.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/sync_indicator.dart';
import 'package:pos/presentation/screen/screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ScrollController scrollController = ScrollController();
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
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: productProvider.filteredItems.length +
                          (productProvider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= productProvider.filteredItems.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final item = productProvider.filteredItems[index];

                        return ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Price: \$${item.standardRate}'),
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

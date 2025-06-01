import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemStockModal extends StatefulWidget {
  const ItemStockModal({Key? key}) : super(key: key);

  @override
  _ItemStockModalState createState() => _ItemStockModalState();
}

class _ItemStockModalState extends State<ItemStockModal> {
  final Color _primaryColor = const Color(0xFF533F77);
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _itemCodes = [];
  String? _selectedItemCode;
  Map<String, List<StockItem>> _stockItems = {};
  String _searchQuery = '';
  bool _isLoading = false;
  String? _cachedSid;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Add focus to search field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedSid = prefs.getString('sid');
    await _fetchStockData();

    // Setup auto refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _fetchStockData();
    });
  }

  Future<void> _fetchStockData({String? searchQuery}) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final limit = searchQuery != null ? 100 : 20;
      final response = await http.post(
        Uri.parse(
            '${dotenv.env['API_URL']}${dotenv.env['CUSTOM_API']}.get_stock'),
        headers: {
          'Cookie': 'sid=$_cachedSid',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'item_code': searchQuery,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final values = data['message']['message']['values'] as List;
        final keys = data['message']['message']['keys'] as List;

        final nameIndex = keys.indexOf('name');
        final itemCodeIndex = keys.indexOf('item_code');
        final warehouseIndex = keys.indexOf('warehouse');
        final actualQtyIndex = keys.indexOf('actual_qty');
        final orderedQtyIndex = keys.indexOf('ordered_qty');
        final reservedQtyIndex = keys.indexOf('reserved_qty');
        final safetyStockIndex = keys.indexOf('safety_stock');

        final stockMap = <String, List<StockItem>>{};
        final itemCodeSet = <String>{};

        for (var item in values) {
          final stockItem = StockItem(
            name: item[nameIndex],
            itemCode: item[itemCodeIndex],
            warehouse: item[warehouseIndex],
            actualQty: item[actualQtyIndex].toDouble(),
            orderedQty: item[orderedQtyIndex].toDouble(),
            reservedQty: item[reservedQtyIndex].toDouble(),
            safetyStock: item[safetyStockIndex].toDouble(),
          );

          stockMap.putIfAbsent(stockItem.itemCode, () => []).add(stockItem);
          itemCodeSet.add(stockItem.itemCode);
        }

        if (mounted) {
          setState(() {
            _stockItems = stockMap;
            _itemCodes = itemCodeSet.toList()..sort();
            if (_itemCodes.isNotEmpty && _selectedItemCode == null) {
              _selectedItemCode = _itemCodes[0];
            }
            _isLoading = false;
          });
        }
      } else {
        _showError('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (query.length >= 2) {
        _fetchStockData(searchQuery: query);
      } else if (query.isEmpty) {
        _fetchStockData();
      } else {
        setState(() => _searchQuery = query.toLowerCase());
      }
    });
  }

  List<String> get _filteredItemCodes {
    if (_searchQuery.isEmpty) return _itemCodes;

    return _itemCodes.where((code) {
      if (code.toLowerCase().contains(_searchQuery)) return true;

      final items = _stockItems[code];
      if (items == null) return false;

      return items
          .any((item) => item.warehouse.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  void _selectItemCode(String itemCode) {
    setState(() => _selectedItemCode = itemCode);
  }

  String _getStockStatusColor(double actualQty, double safetyStock) {
    if (actualQty <= 0) return '#FF5252';
    if (actualQty < safetyStock) return '#FFC107';
    return '#4CAF50';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            _buildLeftSection(),
            _buildRightSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSection() {
    return Expanded(
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
              'Item List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading ? _buildLoadingList() : _buildItemList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        labelText: 'Search by Item Code',
        labelStyle: TextStyle(color: _primaryColor),
        prefixIcon: Icon(Icons.search, color: _primaryColor),
        border: _customOutlineInputBorder(),
        focusedBorder: _customOutlineInputBorder(isFocused: true),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildLoadingList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              'Item Code Example',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (_filteredItemCodes.isEmpty) {
      return Center(
        child: Text(
          'No items found',
          style: TextStyle(color: _primaryColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredItemCodes.length,
      itemBuilder: (context, index) {
        final itemCode = _filteredItemCodes[index];
        final isSelected = _selectedItemCode == itemCode;
        final warehouses = _stockItems[itemCode] ?? [];
        final totalStock =
            warehouses.fold(0.0, (sum, item) => sum + item.actualQty);
        final safetyStock =
            warehouses.fold(0.0, (sum, item) => sum + item.safetyStock);

        return _buildItemCard(
          itemCode: itemCode,
          isSelected: isSelected,
          totalStock: totalStock,
          safetyStock: safetyStock,
        );
      },
    );
  }

  Widget _buildItemCard({
    required String itemCode,
    required bool isSelected,
    required double totalStock,
    required double safetyStock,
  }) {
    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Colors.grey.shade200 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectItemCode(itemCode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemCode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Total: ${totalStock.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse(
                                _getStockStatusColor(totalStock, safetyStock)
                                    .substring(1, 7),
                                radix: 16) +
                            0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSection() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: _selectedItemCode == null
            ? Center(
                child: Text(
                  'Select an item to view stock information',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Text(
                    'Item Code: $_selectedItemCode',
                    style: TextStyle(
                      fontSize: 16,
                      color: _primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildStockList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Stock Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: _primaryColor),
          onPressed: _fetchStockData,
        ),
      ],
    );
  }

  Widget _buildStockList() {
    final items = _stockItems[_selectedItemCode];
    if (items == null || items.isEmpty) {
      return Center(
        child: Text(
          'No stock information available',
          style: TextStyle(color: _primaryColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stockItem = items[index];
        final stockColor = _getStockStatusColor(
          stockItem.actualQty,
          stockItem.safetyStock,
        );

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stockItem.warehouse,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    _buildStockStatusBadge(stockItem, stockColor),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStockInfoRow(
                  'Stock',
                  stockItem.actualQty.toInt().toString(),
                  Color(int.parse(stockColor.substring(1, 7), radix: 16) +
                      0xFF000000),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockStatusBadge(StockItem stockItem, String stockColor) {
    String status;
    if (stockItem.actualQty <= 0) {
      status = 'Out of Stock';
    } else if (stockItem.actualQty < stockItem.safetyStock) {
      status = 'Low Stock';
    } else {
      status = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(
              int.parse(stockColor.substring(1, 7), radix: 16) + 0xFF000000),
        ),
      ),
    );
  }

  Widget _buildStockInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _customOutlineInputBorder({bool isFocused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isFocused ? _primaryColor : Colors.grey.shade400,
        width: isFocused ? 2 : 1,
      ),
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class StockItem {
  final String name;
  final String itemCode;
  final String warehouse;
  final double actualQty;
  final double orderedQty;
  final double reservedQty;
  final double safetyStock;

  const StockItem({
    required this.name,
    required this.itemCode,
    required this.warehouse,
    required this.actualQty,
    required this.orderedQty,
    required this.reservedQty,
    required this.safetyStock,
  });
}

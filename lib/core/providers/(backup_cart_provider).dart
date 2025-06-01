import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/data/api/voucher.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/data/models/voucher/voucher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider class to manage shopping cart functionality including items, vouchers,
/// discounts, and local storage operations.
class CartProvider with ChangeNotifier {
  // Core cart data
  List<CartItem> _cartItems = [];
  List<CartItem> _originalCartItems =
      []; // Stores original data before voucher application
  final List<VoucherModel>? _voucher;

  // Keys for local storage
  static const String _savedTransactionsKey = 'saved_transactions';
  static const String _savedOrdersKey = 'saved_orders';

  // Constructor
  CartProvider({List<VoucherModel>? voucher}) : _voucher = voucher;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  List<VoucherModel>? get voucher => _voucher;

  /// Calculates the total price of all items in the cart
  double get totalPrice => _cartItems.fold(
        0,
        (total, item) => total + (item.amount ?? (item.rate! * item.qty!)),
      );

  /// Calculates the total number of items in the cart
  int get totalItems =>
      _cartItems.fold(0, (total, item) => total + (item.qty ?? 0));

  // ==================== CART MANAGEMENT METHODS ====================

  /// Adds an item to the cart with specified quantity and optional parameters
  void addItem(
    Item item,
    int quantity, {
    String? notes,
    double? discountValue,
    bool isDiscountPercent = true,
    double? totalPrice,
  }) {
    final existingIndex = _findItemIndex(item.itemCode, notes);

    if (existingIndex != -1) {
      // Update quantity if item with same notes already exists
      _updateItemQuantity(existingIndex, quantity, true);
    } else {
      // Add new item to cart
      _cartItems.add(_createCartItemFromProduct(
          item, quantity, notes, discountValue, isDiscountPercent, totalPrice));
    }

    notifyListeners();
  }

  /// Finds index of an item in cart by itemCode and notes
  int _findItemIndex(String? itemCode, String? notes) {
    return _cartItems.indexWhere(
      (cartItem) => cartItem.itemCode == itemCode && cartItem.notes == notes,
    );
  }

  /// Creates a new CartItem from a product Item
  CartItem _createCartItemFromProduct(
    Item item,
    int quantity,
    String? notes,
    double? discountValue,
    bool isDiscountPercent,
    double? customTotalPrice,
  ) {
    final standardRate = item.standardRate?.toInt() ?? 0;
    final baseAmount = standardRate * quantity;

    return CartItem(
      id: CartItem.generateRandomId(),
      itemCode: item.itemCode ?? '-',
      itemName: item.itemName ?? '-',
      description: item.description ?? '-',
      uom: item.stockUom ?? '-',
      conversionFactor: item.standardRate?.toInt() ?? 1,
      qty: quantity,
      rate: standardRate,
      amount: customTotalPrice?.toInt() ??
          _calculateDiscountedPrice(
                  baseAmount.toDouble(), discountValue, isDiscountPercent)
              .toInt(),
      baseRate: standardRate,
      baseAmount: baseAmount,
      priceListRate: standardRate,
      costCenter: "Main - M",
      notes: notes,
      discountValue: discountValue,
      isDiscountPercent: isDiscountPercent,
    );
  }

  /// Adds a pre-configured CartItem to the cart
  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  /// Updates the discount applied to a cart item
  void updateCartItemDiscount(
      String id, double discountValue, bool isDiscountPercent) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final originalPrice = _cartItems[index].baseAmount!.toDouble();
      final newAmount = _calculateDiscountedPrice(
          originalPrice, discountValue, isDiscountPercent);

      _cartItems[index] = _cartItems[index].copyWith(
        discountValue: discountValue,
        isDiscountPercent: isDiscountPercent,
        amount: newAmount.toInt(),
      );
      notifyListeners();
    }
  }

  /// Updates the total price of a cart item directly
  void updateCartItemTotalPrice(String id, double newTotalPrice) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        amount: newTotalPrice.toInt(),
      );
      notifyListeners();
    }
  }

  /// Removes an item from the cart by ID
  void removeCartItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Updates the quantity of an item in the cart
  void updateCartItemQuantity(String id, int newQty) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _updateItemQuantity(index, newQty, false);
      notifyListeners();
    }
  }

  /// Helper method to update item quantity and recalculate prices
  void _updateItemQuantity(int index, int quantityChange, bool isIncrement) {
    final item = _cartItems[index];
    final baseRate = item.baseRate ?? 0;
    final newQty = isIncrement ? (item.qty! + quantityChange) : quantityChange;
    final newBaseAmount = baseRate * newQty;

    final newAmount = _calculateDiscountedPrice(
      newBaseAmount.toDouble(),
      item.discountValue,
      item.isDiscountPercent ?? true,
    ).toInt();

    _cartItems[index] = item.copyWith(
      qty: newQty,
      amount: newAmount,
    );
  }

  /// Updates the notes for a cart item
  void updateCartItemNotes(String id, String? newNotes) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(notes: newNotes);
      notifyListeners();
    }
  }

  /// Removes all items from the cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Calculates price after applying discount
  double _calculateDiscountedPrice(
      double originalPrice, double? discountValue, bool isPercent) {
    if (discountValue == null || discountValue <= 0) {
      return originalPrice;
    }
    if (isPercent) {
      return originalPrice - (originalPrice * (discountValue / 100));
    }
    return originalPrice - discountValue;
  }

  // ==================== VOUCHER METHODS ====================

  /// Applies a voucher to the current cart items
  Future<Map<String, dynamic>> useVoucher(
      VoucherModel voucher, List<CartItem> cartItems, String customer) async {
    // Backup original cart state
    _originalCartItems = _cartItems.map((item) => item.copyWith()).toList();

    // Get session data
    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getString('company_name');
    final outlet = prefs.getString('selected_outlet');
    final discountType = voucher.discountType;

    // Prepare response data structure
    Map<String, dynamic> result =
        _createInitialVoucherResult(voucher, discountType);

    try {
      // Prepare data for API
      final apiRequestData = await _prepareVoucherApiData(
          voucher, cartItems, discountType, company, outlet, customer);

      if (apiRequestData['vouchers'].isEmpty) {
        result['message'] = 'Data voucher kosong';
        return result;
      }

      // Call API
      final response = await calculateVoucher(apiRequestData);

      // Process API response
      if (_isVoucherApiResponseSuccessful(response)) {
        return _processSuccessfulVoucherResponse(
            response!, result, voucher, discountType);
      } else {
        result['message'] =
            response?['message']?['message'] ?? 'Gagal menerapkan voucher';
        return result;
      }
    } catch (e) {
      result['message'] = 'Error: $e';
      return result;
    }
  }

  /// Creates initial result data structure for voucher application
  Map<String, dynamic> _createInitialVoucherResult(
      VoucherModel voucher, String? discountType) {
    return {
      'status': 'gagal',
      'voucher_name': voucher.name,
      'voucher_type': discountType,
      'discount_details': [],
      'total_discount': 0.0,
      'original_total': totalPrice,
      'final_total': totalPrice,
      'message': 'Gagal menerapkan voucher'
    };
  }

  /// Prepares data for voucher API request
  Future<Map<String, dynamic>> _prepareVoucherApiData(
      VoucherModel voucher,
      List<CartItem> cartItems,
      String? discountType,
      String? company,
      String? outlet,
      String customer) async {
    final List<Map<String, dynamic>> dataItems = [];
    final List<Map<String, dynamic>> dataVoucher = [];

    // Prepare items data
    for (var item in cartItems) {
      for (int j = 0; j < (item.qty ?? 0); j++) {
        dataItems.add({
          "item_idx": item.itemCode,
          "item_code": item.itemCode,
          "uom": item.uom,
          "qty": 1, // Send each item with qty=1
        });
      }
    }

    // Prepare voucher data based on discount type
    if (discountType == "Cash Discount") {
      dataVoucher.add({"voucher": voucher.name});
    } else if (discountType == "Discount on Cheapest") {
      await _prepareDiscountOnCheapestVoucherData(
          voucher, cartItems, dataVoucher);
    } else if (discountType == "Target Price") {
      _prepareTargetPriceVoucherData(voucher, cartItems, dataVoucher);
    }

    return {
      "company": company,
      "posting_date": DateTime.now().toIso8601String(),
      "posting_time": DateTime.now().toIso8601String(),
      "base_net_total": totalPrice,
      "customer": customer,
      "pos_profile": outlet,
      "items": dataItems,
      "vouchers": dataVoucher
    };
  }

  /// Prepares voucher data for "Discount on Cheapest" type
  Future<void> _prepareDiscountOnCheapestVoucherData(VoucherModel voucher,
      List<CartItem> cartItems, List<Map<String, dynamic>> dataVoucher) async {
    final response = await getVoucherById(voucher.name!);

    Map<String, dynamic> responseData = {};
    if (response != null && response.containsKey('data')) {
      responseData = response['data'];
    }

    int qtyRequired = voucher.qtyRequired ?? 1;
    int qtyDiscounted = voucher.qtyDiscounted ?? 1;

    // Process required items
    List<Map<String, dynamic>> requiredItems =
        _extractItemListFromResponse(responseData, 'table_tixu', 'item');

    if (requiredItems.isEmpty) {
      requiredItems = _getItemsByPriceOrder(cartItems, qtyRequired, true);
    }

    // Process discounted items
    List<Map<String, dynamic>> discountedItems =
        _extractItemListFromResponse(responseData, 'table_fddb', 'item');

    if (discountedItems.isEmpty) {
      discountedItems = _getItemsByPriceOrder(cartItems, qtyDiscounted, false);
    }

    dataVoucher.add({
      "voucher": voucher.name,
      "required_items": requiredItems,
      "discounted_items": discountedItems,
    });
  }

  /// Extracts item list from voucher API response
  List<Map<String, dynamic>> _extractItemListFromResponse(
      Map<String, dynamic> responseData, String tableKey, String itemKey) {
    List<Map<String, dynamic>> items = [];

    if (responseData.containsKey(tableKey) && responseData[tableKey] is List) {
      for (var item in responseData[tableKey]) {
        if (item is Map && item.containsKey(itemKey)) {
          items.add({"name": item[itemKey]});
        }
      }
    }

    return items;
  }

  /// Gets items sorted by price (highest or lowest)
  List<Map<String, dynamic>> _getItemsByPriceOrder(
      List<CartItem> items, int count, bool highestFirst) {
    List<CartItem> sorted = [...items];
    sorted.sort((a, b) => highestFirst
        ? (b.rate ?? 0).compareTo(a.rate ?? 0)
        : (a.rate ?? 0).compareTo(b.rate ?? 0));

    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < count && i < sorted.length; i++) {
      result.add({"name": sorted[i].itemCode});
    }

    return result;
  }

  /// Prepares voucher data for "Target Price" type
  void _prepareTargetPriceVoucherData(VoucherModel voucher,
      List<CartItem> cartItems, List<Map<String, dynamic>> dataVoucher) {
    final discountedItems = cartItems
        .map((item) => {
              "name": item.itemCode,
            })
        .toList();

    dataVoucher
        .add({"voucher": voucher.name, "discounted_item": discountedItems});
  }

  /// Checks if voucher API response was successful
  bool _isVoucherApiResponseSuccessful(Map<String, dynamic>? response) {
    return response != null &&
        response.containsKey('message') &&
        response['message'].containsKey('success_key') &&
        response['message']['success_key'] == 1;
  }

  /// Processes successful voucher API response and updates cart items
  Map<String, dynamic> _processSuccessfulVoucherResponse(
      Map<String, dynamic> response,
      Map<String, dynamic> result,
      VoucherModel voucher,
      String? discountType) {
    final apiData = response['message']['data'];

    // Update basic result info
    result['status'] = 'sukses';
    result['message'] =
        response['message']['message'] ?? 'Voucher berhasil diterapkan';

    double totalDiscount = 0.0;
    double finalTotal = 0.0;
    List<Map<String, dynamic>> discountDetails = [];

    // Process items if available
    if (apiData != null &&
        apiData.containsKey('items') &&
        apiData['items'] is List) {
      // Group items by item_code for easier processing
      Map<String, List<Map<String, dynamic>>> groupedItems =
          _groupApiItemsByCode(apiData['items']);

      // Update cart items with discount information
      for (int i = 0; i < _cartItems.length; i++) {
        String? itemCode = _cartItems[i].itemCode;

        if (groupedItems.containsKey(itemCode)) {
          // Process this item's discounts
          final itemDiscountInfo = _calculateItemDiscountFromApi(
              _cartItems[i], groupedItems[itemCode]!);

          // Update cart item
          _cartItems[i] = _cartItems[i].copyWith(
            amount: itemDiscountInfo['newAmount'].toInt(),
            discountValue: itemDiscountInfo['totalDiscount'],
            isDiscountPercent: false,
            voucherApplied: true,
          );

          // Add to discount details
          discountDetails.add(itemDiscountInfo['details']);

          // Update totals
          totalDiscount += itemDiscountInfo['totalDiscount'];
          finalTotal += itemDiscountInfo['newAmount'];
        }
      }

      // Update result with detailed information
      result['discount_details'] = discountDetails;
      result['total_discount'] = totalDiscount;
      result['final_total'] = finalTotal;

      // Add voucher summary
      result['voucher_summary'] = _createVoucherSummary(
          voucher, discountType, totalDiscount, discountDetails.length);

      // Add overall discount info if available
      if (apiData.containsKey('total_before_discount') &&
          apiData.containsKey('grand_total')) {
        result['total_before_discount'] = apiData['total_before_discount'];
        result['grand_total'] = apiData['grand_total'];
      }

      notifyListeners();
    }

    return result;
  }

  /// Groups API response items by their item_code
  Map<String, List<Map<String, dynamic>>> _groupApiItemsByCode(List apiItems) {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var apiItem in apiItems) {
      String itemCode = apiItem['item_code'];
      if (!groupedItems.containsKey(itemCode)) {
        groupedItems[itemCode] = [];
      }
      groupedItems[itemCode]!.add(apiItem);
    }

    return groupedItems;
  }

  /// Calculates discount information for a single item from API response
  Map<String, dynamic> _calculateItemDiscountFromApi(
      CartItem item, List<Map<String, dynamic>> apiItems) {
    double totalItemDiscount = 0.0;
    double newAmount = 0.0;
    double originalAmount = item.baseRate?.toDouble() ?? 0.0;
    double qty = item.qty?.toDouble() ?? 0.0;

    for (var apiItem in apiItems) {
      totalItemDiscount += apiItem['discount_amount']?.toDouble() ?? 0.0;
      newAmount += apiItem['amount']?.toDouble() ?? 0.0;
    }

    // Calculate discount percentage
    String discountPercentage = originalAmount > 0
        ? ((totalItemDiscount / (originalAmount * qty)) * 100)
                .toStringAsFixed(2) +
            '%'
        : '0%';

    return {
      'totalDiscount': totalItemDiscount,
      'newAmount': newAmount,
      'details': {
        'item_code': item.itemCode,
        'item_name': item.itemName,
        'original_price': originalAmount,
        'discount_amount': totalItemDiscount,
        'final_price': newAmount,
        'qty': qty,
        'discount_percentage': discountPercentage
      }
    };
  }

  /// Creates voucher summary information
  Map<String, dynamic> _createVoucherSummary(VoucherModel voucher,
      String? discountType, double totalDiscount, int itemsDiscounted) {
    return {
      'voucher_name': voucher.name,
      'voucher_description': voucher.description ?? '',
      'discount_type': discountType,
      'total_discount_applied': totalDiscount,
      'percentage_saved': totalPrice > 0
          ? ((totalDiscount / totalPrice) * 100).toStringAsFixed(2) + '%'
          : '0%',
      'total_items_discounted': itemsDiscounted,
    };
  }

  /// Resets voucher application and restores original cart items
  void resetVoucher() {
    if (_originalCartItems.isNotEmpty) {
      _cartItems = _originalCartItems.map((item) => item.copyWith()).toList();
      _originalCartItems.clear();
      notifyListeners();
    }
  }

  // ==================== LOCAL STORAGE METHODS ====================

  /// Saves current cart as a transaction with customer info
  Future<void> saveCartToLocalStorage(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await _loadTransactionsFromStorage(prefs);

    final newTransaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'items': _cartItems.map((item) => item.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'customer': customer.toJson(),
    };

    transactions.add(newTransaction);
    await _saveTransactionsToStorage(prefs, transactions);
  }

  /// Loads saved transactions from local storage
  Future<List<Map<String, dynamic>>> loadCartFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadTransactionsFromStorage(prefs);
  }

  /// Helper to load transactions from SharedPreferences
  Future<List<Map<String, dynamic>>> _loadTransactionsFromStorage(
      SharedPreferences prefs) async {
    final data = prefs.getString(_savedTransactionsKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  /// Helper to save transactions to SharedPreferences
  Future<void> _saveTransactionsToStorage(
      SharedPreferences prefs, List<Map<String, dynamic>> transactions) async {
    await prefs.setString(_savedTransactionsKey, json.encode(transactions));
    notifyListeners();
  }

  /// Deletes a transaction by ID
  Future<void> deleteTransactionById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_savedTransactionsKey);
    if (data == null) return;

    List<Map<String, dynamic>> transactions =
        List<Map<String, dynamic>>.from(json.decode(data));

    transactions.removeWhere((t) => t['id'] == id);
    await prefs.setString(_savedTransactionsKey, json.encode(transactions));
    notifyListeners();
  }

  /// Saves order information
  Future<void> savePesanan(
      String invoiceNumber,
      String customerName,
      List<CartItem> items,
      String customerAddress,
      String customerPhone) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await _loadOrdersFromStorage(prefs);

    final newOrder = {
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    orders.add(newOrder);
    await _saveOrdersToStorage(prefs, orders);
  }

  /// Loads saved orders from local storage
  Future<List<Map<String, dynamic>>> loadPesanan() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadOrdersFromStorage(prefs);
  }

  /// Helper to load orders from SharedPreferences
  Future<List<Map<String, dynamic>>> _loadOrdersFromStorage(
      SharedPreferences prefs) async {
    final data = prefs.getString(_savedOrdersKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  /// Helper to save orders to SharedPreferences
  Future<void> _saveOrdersToStorage(
      SharedPreferences prefs, List<Map<String, dynamic>> orders) async {
    await prefs.setString(_savedOrdersKey, json.encode(orders));
    notifyListeners();
  }

  /// Deletes an order by invoice number
  Future<void> deletePesananById(String invoiceNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_savedOrdersKey);
    if (data == null) return;

    List<Map<String, dynamic>> orders =
        List<Map<String, dynamic>>.from(json.decode(data));

    orders.removeWhere((order) => order['invoiceNumber'] == invoiceNumber);
    await prefs.setString(_savedOrdersKey, json.encode(orders));
    notifyListeners();
  }
}

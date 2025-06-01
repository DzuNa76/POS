import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/data/api/voucher.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/customer/customer.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/data/models/voucher/voucher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  List<CartItem> _cartSaveBill = [];
  List<CartItem> _originalCartItems =
      []; // Untuk menyimpan data asli sebelum voucher
  final List<VoucherModel>? _voucher; // Untuk menyimpan data voucher

  CartProvider({List<VoucherModel>? voucher}) : _voucher = voucher;

  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get cartSaveBill => _cartSaveBill;
  List<VoucherModel>? get voucher => _voucher;

  /// Getter untuk menghitung total harga semua item di keranjang
  double get totalPrice => _cartItems.fold(
        0,
        (total, item) => total + (item.amount ?? (item.rate! * item.qty!)),
      );

  void addItem(
    Item item,
    int quantity, {
    String? notes,
    double? discountValue, // Diskon nominal
    bool isDiscountPercent = true, // Default: diskon dalam persen
    double? totalPrice, // Tambahkan total harga
  }) {
    final existingIndex = _cartItems.indexWhere(
      (cartItem) =>
          cartItem.itemCode == item.itemCode && cartItem.notes == notes,
    );

    if (existingIndex != -1) {
      // Jika item dengan catatan yang sama sudah ada di keranjang, perbarui kuantitas
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        qty: _cartItems[existingIndex].qty! + quantity,
      );
    } else {
      // Jika item dengan catatan berbeda atau baru, tambahkan item baru
      _cartItems.add(CartItem(
        id: CartItem.generateRandomId(),
        itemCode: item.itemCode ?? '-',
        itemName: item.itemName ?? '-',
        description: item.description ?? '-',
        uom: item.stockUom ?? '-',
        conversionFactor: item.standardRate?.toInt() ?? 1,
        qty: quantity,
        rate: item.standardRate?.toInt() ?? 0,
        amount: totalPrice?.toInt() ??
            _calculateDiscountedPrice(
              (item.standardRate ?? 0.0) * quantity,
              discountValue,
              isDiscountPercent,
            ).toInt(),
        baseRate: item.standardRate?.toInt() ?? 0,
        baseAmount: (item.standardRate?.toInt() ?? 0) * quantity,
        priceListRate: item.standardRate?.toInt() ?? 0,
        costCenter: "Main - M",
        notes: notes,
        discountValue: discountValue,
        isDiscountPercent: isDiscountPercent,
      ));
    }

    notifyListeners();
  }

  /// Getter untuk menghitung jumlah total item di keranjang
  int get totalItems => _cartItems.fold(0, (total, item) => total + item.qty!);

  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  // START OF VOUCHER
  Future<Map<String, dynamic>> useVoucher(
      VoucherModel voucher, List<CartItem> cartItem, String customer) async {
    _originalCartItems = _cartItems.map((item) => item.copyWith()).toList();

    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getString('company_name');
    final outlet = prefs.getString('selected_outlet');
    final discount_type = voucher.discountType;

    final data_items = [];
    final data_voucher = [];

    // Prepare result data with initial information
    Map<String, dynamic> result = {
      'status': 'gagal',
      'voucher_name': voucher.name,
      'voucher_type': discount_type,
      'discount_details': [],
      'total_discount': 0.0,
      'original_total': totalPrice,
      'final_total': totalPrice,
      'message': 'Gagal menerapkan voucher'
    };

    // Create a map to track items by their item code
    Map<String, CartItem> itemCodeToCartItem = {};
    for (var item in _cartItems) {
      itemCodeToCartItem[item.itemCode!] = item;
    }

    // Prepare items data for API call
    for (int i = 0; i < cartItem.length; i++) {
      final item = cartItem[i];
      data_items.add({
        "item_idx": item.itemCode,
        "item_code": item.itemCode,
        "uom": item.uom,
        "qty": item.qty,
      });
    }

    if (discount_type == "Cash Discount") {
      data_voucher.add({"voucher": voucher.name});

      // discount on cheapest sulit sekali wkwk
    } else if (discount_type == "Discount on Cheapest") {
      // Mendapatkan informasi voucher dari API
      final response = await getVoucherById(voucher.name!);

      Map<String, dynamic> responseData = {};
      if (response != null && response.containsKey('data')) {
        responseData = response['data'];
      }

      int qtyRequired = voucher.qtyRequired ?? 1;
      int qtyDiscounted = voucher.qtyDiscounted ?? 1;

      // determine which item is more expensive based on the rate
      List<CartItem> cartItemsByRate = [...cartItems];
      cartItemsByRate.sort((a, b) {
        // Pertama bandingkan berdasarkan harga (dari tinggi ke rendah)
        int rateComparison = (b.rate ?? 0).compareTo(a.rate ?? 0);
        if (rateComparison != 0) return rateComparison;

        // Jika harga sama, prioritaskan item dengan qty lebih banyak
        return (b.qty ?? 0).compareTo(a.qty ?? 0);
      });

      // Keep track of what items we have and their properties
      Map<String, Map<String, dynamic>> itemDetails = {};
      for (var item in cartItems) {
        if (item.itemCode != null) {
          itemDetails[item.itemCode!] = {
            'rate': item.rate ?? 0,
            'qty': item.qty ?? 0,
            'usedForRequired': 0,
            'usedForDiscount': 0
          };
        }
      }

      List<String> itemCodesByExpensive = [];
      List<String> itemCodesByCheap = [];

      // Create sorted lists of item codes
      for (var item in cartItemsByRate) {
        if (item.itemCode != null) {
          itemCodesByExpensive.add(item.itemCode!);
        }
      }

      // Cheapest items (reverse of expensive)
      itemCodesByCheap = List.from(itemCodesByExpensive.reversed);

      // Log the explicitly identified expensive and cheap items
      print("Most expensive item codes: $itemCodesByExpensive");
      print("Cheapest item codes: $itemCodesByCheap");

      // Prepare lists for required and discounted items
      List<Map<String, dynamic>> requiredItems = [];
      List<Map<String, dynamic>> discountedItems = [];

      // STEP 1: Fill required_items from most expensive to least,
      // using full quantities of each item type
      for (String itemCode in itemCodesByExpensive) {
        int remainingForRequired = qtyRequired - requiredItems.length;
        if (remainingForRequired <= 0) break;

        int availableQty = itemDetails[itemCode]!['qty'];
        int toUse = min(availableQty, remainingForRequired);

        for (int i = 0; i < toUse; i++) {
          requiredItems.add({"name": itemCode});
          itemDetails[itemCode]!['usedForRequired']++;
        }
      }

      // STEP 2: Fill discounted_items from cheapest to most expensive,
      // using full quantities of each item type
      for (String itemCode in itemCodesByCheap) {
        int remainingForDiscount = qtyDiscounted - discountedItems.length;
        if (remainingForDiscount <= 0) break;

        int availableQty = itemDetails[itemCode]!['qty'] -
            itemDetails[itemCode]!['usedForRequired'];
        int toUse = min(availableQty, remainingForDiscount);

        for (int i = 0; i < toUse; i++) {
          discountedItems.add({"name": itemCode});
          itemDetails[itemCode]!['usedForDiscount']++;
        }
      }

      // // Log the selected items
      print(
          "Selected required items: ${requiredItems.map((item) => item['name']).toList()}");
      print(
          "Selected discounted items: ${discountedItems.map((item) => item['name']).toList()}");
      print("Item details after selection: $itemDetails");

      // SPECIAL CASE: Handle server-specified required items if present
      if (responseData.containsKey('required_items') &&
          responseData['required_items'] is List &&
          (responseData['required_items'] as List).isNotEmpty) {
        // Check if we already have enough required items from our selection
        bool hasEnoughRequiredItems = requiredItems.length >= qtyRequired;

        // Only modify the selection if we don't have enough items yet
        if (!hasEnoughRequiredItems) {
          // Clear previous selections
          for (var entry in itemDetails.entries) {
            itemDetails[entry.key]!['usedForRequired'] = 0;
          }
          requiredItems.clear();

          // Extract server-specified required items
          Map<String, int> requiredItemsFromServer = {};
          for (var item in responseData['required_items']) {
            if (item is Map && item.containsKey('item')) {
              String itemCode = item['item'];
              requiredItemsFromServer[itemCode] =
                  (requiredItemsFromServer[itemCode] ?? 0) + 1;
            }
          }

          // Add server-specified items first
          int totalAdded = 0;
          for (var entry in requiredItemsFromServer.entries) {
            String itemCode = entry.key;
            int countNeeded = entry.value;

            // Skip if item not in cart
            if (!itemDetails.containsKey(itemCode)) continue;

            // Pastikan tidak melebihi qty yang tersedia
            int availableQty = itemDetails[itemCode]!['qty'];
            int toAdd =
                min(countNeeded, min(availableQty, qtyRequired - totalAdded));

            for (int i = 0; i < toAdd; i++) {
              requiredItems.add({"name": itemCode});
              itemDetails[itemCode]!['usedForRequired']++;
              totalAdded++;
            }

            if (totalAdded >= qtyRequired) break;
          }

          // If still need more, add from expensive items
          if (totalAdded < qtyRequired) {
            for (String itemCode in itemCodesByExpensive) {
              int remainingQty = itemDetails[itemCode]!['qty'] -
                  itemDetails[itemCode]!['usedForRequired'];
              int toAdd = min(remainingQty, qtyRequired - totalAdded);

              for (int i = 0; i < toAdd; i++) {
                requiredItems.add({"name": itemCode});
                itemDetails[itemCode]!['usedForRequired']++;
                totalAdded++;
              }

              if (totalAdded >= qtyRequired) break;
            }
          }
        }
      }

      // SPECIAL CASE: Handle server-specified discounted items if present
      if (responseData.containsKey('discounted_items') &&
          responseData['discounted_items'] is List &&
          (responseData['discounted_items'] as List).isNotEmpty) {
        // Selalu gunakan discounted items dari server jika tersedia
        // Clear previous discount selections
        for (var entry in itemDetails.entries) {
          itemDetails[entry.key]!['usedForDiscount'] = 0;
        }
        discountedItems.clear();

        // Extract server-specified discounted items
        Map<String, int> discountedItemsFromServer = {};
        for (var item in responseData['discounted_items']) {
          if (item is Map && item.containsKey('item')) {
            String itemCode = item['item'];
            // Hanya tambahkan item yang ada di keranjang
            if (itemDetails.containsKey(itemCode)) {
              discountedItemsFromServer[itemCode] =
                  (discountedItemsFromServer[itemCode] ?? 0) + 1;
            }
          }
        }

        // Add server-specified items first
        int totalAdded = 0;
        for (var entry in discountedItemsFromServer.entries) {
          String itemCode = entry.key;
          int countNeeded = entry.value;

          // Skip if item not in cart
          if (!itemDetails.containsKey(itemCode)) continue;

          // Periksa ketersediaan setelah dikurangi yang digunakan untuk required items
          int availableQty = itemDetails[itemCode]!['qty'] -
              itemDetails[itemCode]!['usedForRequired'];
          if (availableQty <= 0) continue;

          // Gunakan semua item yang tersedia, maksimal sebanyak qtyDiscounted
          int toAdd = min(availableQty, qtyDiscounted - totalAdded);

          // Pastikan tidak melebihi jumlah yang dibutuhkan dari server
          // Hapus baris ini untuk menggunakan semua item yang tersedia
          // toAdd = min(toAdd, countNeeded);

          for (int i = 0; i < toAdd; i++) {
            discountedItems.add({"name": itemCode});
            itemDetails[itemCode]!['usedForDiscount']++;
            totalAdded++;
          }

          if (totalAdded >= qtyDiscounted) break;
        }

        // Jika masih kurang, tambahkan dari item termurah HANYA jika tidak ada item dari server
        if (totalAdded < qtyDiscounted && discountedItemsFromServer.isEmpty) {
          for (String itemCode in itemCodesByCheap) {
            int remainingQty = itemDetails[itemCode]!['qty'] -
                itemDetails[itemCode]!['usedForRequired'] -
                itemDetails[itemCode]!['usedForDiscount'];
            int toAdd = min(remainingQty, qtyDiscounted - totalAdded);

            for (int i = 0; i < toAdd; i++) {
              discountedItems.add({"name": itemCode});
              itemDetails[itemCode]!['usedForDiscount']++;
              totalAdded++;
            }

            if (totalAdded >= qtyDiscounted) break;
          }
        }
      }
      // // Final log for debugging
      print(
          "Final required items: ${requiredItems.map((item) => item['name']).toList()}");
      print(
          "Final discounted items: ${discountedItems.map((item) => item['name']).toList()}");
      print("Final item details: $itemDetails");

      // Add to voucher data for API request
      data_voucher.add({
        "voucher": voucher.name,
        "required_items": requiredItems,
        "discounted_items": discountedItems,
      });

      result['requirements'] = {
        'required_items': requiredItems.map((item) => item['name']).toList(),
        'discounted_items':
            discountedItems.map((item) => item['name']).toList(),
      };
    } else if (discount_type == "Target Price") {
      final discounted_items = [];
      for (int i = 0; i < cartItem.length; i++) {
        final item = cartItem[i];
        final name = item.itemCode;
        discounted_items.add({
          "name": name,
        });
      }
      data_voucher
          .add({"voucher": voucher.name, "discounted_item": discounted_items});
    }

    // Format tanggal dan waktu sesuai contoh yang berhasil
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm:ss');

    final dataPosting = {
      "company": company,
      "posting_date": dateFormatter.format(now), // Format: YYYY-MM-DD
      "posting_time": timeFormatter.format(now), // Format: HH:MM:SS
      "base_net_total": totalPrice,
      "customer": customer,
      "pos_profile": outlet,
      "items": data_items,
      "vouchers": data_voucher
    };

    // Log data posting untuk troubleshooting
    print("Posting data to voucher API:");
    print(jsonEncode(dataPosting));

    try {
      if (data_voucher.isNotEmpty) {
        final response = await calculateVoucher(dataPosting);

        if (response != null &&
            response.containsKey('message') &&
            response['message'].containsKey('success_key') &&
            response['message']['success_key'] == 1) {
          // Extract data from response
          final apiData = response['message']['data'];

          // Update success status and message
          result['status'] = 'sukses';
          result['message'] =
              response['message']['message'] ?? 'Voucher berhasil diterapkan';

          double totalDiscount = 0.0;
          double finalTotal = 0.0;

          // Process API response and update cart items
          if (apiData != null &&
              apiData.containsKey('items') &&
              apiData['items'] is List) {
            final apiItems = apiData['items'] as List;
            List<Map<String, dynamic>> discountDetails = [];

            // Group API items by item_code
            Map<String, List<Map<String, dynamic>>> groupedItems = {};
            for (var apiItem in apiItems) {
              String itemCode = apiItem['item_code'];
              if (!groupedItems.containsKey(itemCode)) {
                groupedItems[itemCode] = [];
              }
              groupedItems[itemCode]!.add(apiItem);
            }

            // Process each cart item
            for (int i = 0; i < _cartItems.length; i++) {
              String? itemCode = _cartItems[i].itemCode;
              if (groupedItems.containsKey(itemCode)) {
                List<Map<String, dynamic>> items = groupedItems[itemCode]!;

                // Aggregate discounts and calculate new amount for this item
                double totalItemDiscount = 0.0;
                double newAmount = 0.0;
                double originalAmount =
                    _cartItems[i].baseRate?.toDouble() ?? 0.0;
                double qty = _cartItems[i].qty?.toDouble() ?? 0.0;

                for (var item in items) {
                  totalItemDiscount +=
                      item['discount_amount']?.toDouble() ?? 0.0;
                  newAmount += item['amount']?.toDouble() ?? 0.0;
                }

                // Update cart item
                _cartItems[i] = _cartItems[i].copyWith(
                  amount: newAmount.toInt(),
                  discountValue: totalItemDiscount,
                  isDiscountPercent: false,
                  voucherApplied: true,
                );

                // Add to discount details
                discountDetails.add({
                  'item_code': itemCode,
                  'item_name': _cartItems[i].itemName,
                  'original_price': originalAmount,
                  'discount_amount': totalItemDiscount,
                  'final_price': newAmount,
                  'qty': qty,
                  'discount_percentage': originalAmount > 0
                      ? '${((totalItemDiscount / (originalAmount * qty)) * 100).toStringAsFixed(2)}%'
                      : '0%'
                });

                // Update totals
                totalDiscount += totalItemDiscount;
                finalTotal += newAmount;
              }
            }

            // Update result with discount details
            result['discount_details'] = discountDetails;
            result['total_discount'] = totalDiscount;
            result['final_total'] = finalTotal;

            // Add voucher summary information
            result['voucher_summary'] = {
              'voucher_name': voucher.name,
              'voucher_description': voucher.description ?? '',
              'discount_type': discount_type,
              'total_discount_applied': totalDiscount,
              'percentage_saved': totalPrice > 0
                  ? ((totalDiscount / totalPrice) * 100).toStringAsFixed(2) +
                      '%'
                  : '0%',
              'total_items_discounted': discountDetails.length,
            };

            // Check if api data contains overall discount information
            if (apiData.containsKey('total_before_discount') &&
                apiData.containsKey('grand_total')) {
              result['total_before_discount'] =
                  apiData['total_before_discount'];
              result['grand_total'] = apiData['grand_total'];
            }

            notifyListeners();
          }

          return result; // Return detailed success info
        } else {
          // Update with error information
          String errorMessage = 'Terjadi kesalahan saat menerapkan voucher.';

          if (response!.containsKey('_server_messages')) {
            try {
              // _server_messages biasanya string JSON array, misal: '["{...}"]'
              final serverMessages = jsonDecode(response['_server_messages']);
              if (serverMessages is List && serverMessages.isNotEmpty) {
                final firstMsg = jsonDecode(serverMessages.first);
                if (firstMsg.containsKey('message')) {
                  errorMessage = firstMsg['message'];
                }
              }
            } catch (e) {
              // Fallback jika parsing gagal
              errorMessage = response['exception'] ??
                  'Voucher tidak valid atau terjadi kesalahan lainnya.';
            }
          } else if (response.containsKey('exception')) {
            errorMessage = response['exception'];
          }

          result['status'] = 'gagal';
          result['message'] = errorMessage;

          return result; // Return error info
        }
      } else {
        // Update with error information
        result['message'] = 'Data voucher kosong';
        return result; // Return error info
      }
    } catch (e) {
      // Update with exception information
      result['message'] = 'Errors: $e';
      return result; // Return exception info
    }
  }

  // Fungsi untuk reset voucher
  void resetVoucher() {
    if (_originalCartItems.isNotEmpty) {
      _cartItems = _originalCartItems.map((item) => item.copyWith()).toList();
      _originalCartItems.clear();
      notifyListeners();
    }
  }
  // END OF VOUCHER

  void updateCartItemDiscount(
      String id, double discountValue, bool isDiscountPercent) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final originalPrice = _cartItems[index].baseAmount; // Ambil harga asli
      final newAmount = _calculateDiscountedPrice(
          originalPrice!.toDouble(), discountValue, isDiscountPercent);

      // Perbarui item dengan diskon baru
      _cartItems[index] = _cartItems[index].copyWith(
        discountValue: discountValue,
        isDiscountPercent: isDiscountPercent,
        amount: newAmount.toInt(), // Total setelah diskon
      );
      notifyListeners();
    }
  }

  void updateCartItemTotalPrice(String id, double newTotalPrice) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        amount: newTotalPrice.toInt(),
      );
      notifyListeners();
    }
  }

  void removeCartItem(String id) {
    // Menghapus item dengan ID yang sesuai
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateCartItemQuantity(String id, int newQty) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      // Hitung harga baru berdasarkan kuantitas baru
      final baseRate = _cartItems[index].baseRate ?? 0;
      final newBaseAmount = baseRate * newQty;

      // Terapkan diskon jika ada
      final discountValue = _cartItems[index].discountValue;
      final isDiscountPercent = _cartItems[index].isDiscountPercent ?? true;
      final newAmount = _calculateDiscountedPrice(
              newBaseAmount.toDouble(), discountValue, isDiscountPercent)
          .toInt();

      // Perbarui item dengan kuantitas dan harga baru
      _cartItems[index] = _cartItems[index].copyWith(
        qty: newQty,
        amount: newAmount,
      );
      notifyListeners();
    }
  }

  void updateCartItemNotes(String id, String? newNotes) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(notes: newNotes);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

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

  /// Simpan keranjang saat ini sebagai transaksi baru
  Future<void> saveCartToLocalStorage(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil transaksi yang sudah ada
    final existing = prefs.getString('saved_transactions');
    List<Map<String, dynamic>> transactions = [];

    if (existing != null) {
      transactions = List<Map<String, dynamic>>.from(json.decode(existing));
    }

    // Buat transaksi baru
    final newTransaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'items': _cartItems.map((item) => item.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'customer': customer.toJson(),
    };

    transactions.add(newTransaction);

    await prefs.setString('saved_transactions', json.encode(transactions));
    notifyListeners();
  }

  /// Ambil semua transaksi yang sudah disimpan
  Future<List<Map<String, dynamic>>> loadCartFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_transactions');

    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  /// Hapus transaksi berdasarkan ID
  Future<void> deleteTransactionById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_transactions');
    if (data == null) return;

    List<Map<String, dynamic>> transactions =
        List<Map<String, dynamic>>.from(json.decode(data));

    transactions.removeWhere((t) => t['id'] == id);

    await prefs.setString('saved_transactions', json.encode(transactions));
    notifyListeners();
  }

  Future<void> savePesanan(
      String invoiceNumber,
      String customerName,
      List<CartItem> items,
      String customerAddress,
      String customerPhone) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve existing orders
    final existing = prefs.getString('saved_orders');
    List<Map<String, dynamic>> orders = [];

    if (existing != null) {
      orders = List<Map<String, dynamic>>.from(json.decode(existing));
    }

    // Create new order
    final newOrder = {
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    orders.add(newOrder);

    await prefs.setString('saved_orders', json.encode(orders));
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadPesanan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_orders');

    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  Future<void> deletePesananById(String invoiceNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_orders');
    if (data == null) return;

    List<Map<String, dynamic>> orders =
        List<Map<String, dynamic>>.from(json.decode(data));

    orders.removeWhere((order) => order['invoiceNumber'] == invoiceNumber);

    await prefs.setString('saved_orders', json.encode(orders));
    notifyListeners();
  }
}

// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/widgets.dart';
// import 'package:pos/presentation/providers/app_state.dart';

// // if you got error on appState, write this in your APPState file
// // import 'package:you_app_name/your_path_to/cart.dart';
// // static List<CartItem> cartItems = []; // New static list to store cart items
// // static void updateCart(List<CartItem> items) {
// //   cartItems = items;
// // }
// class CartVoucher {
//   final String id;
//   final String name;
//   final int totalDiscount;
//   final Map voucher;

//   CartVoucher({
//     required this.id,
//     required this.name,
//     required this.totalDiscount,
//     required this.voucher,
//   }) {}
// }

// enum CartMode {
//   update, // Update the quantity if the item already exists
//   add, // Add a new item if it doesn't exist
// }

// class CartItem {
//   final String id;
//   final String name;
//   final String itemName;
//   int qty;
//   final Map<String, String>? preference;
//   final int price;
//   late int totalPrice;
//   String? notes;
//   Map<String, Map<String, dynamic>>? addon;
//   final double discount;

//   CartItem({
//     required this.id,
//     required this.name,
//     required this.itemName,
//     required this.qty,
//     this.preference,
//     required this.price,
//     this.notes,
//     this.addon,
//     this.discount = 0.0,
//   }) {
//     totalPrice = qty * price;
//   }

//   // Pastikan preference selalu memiliki nilai default (tidak null)
//   Map<String, String> get safePreference => preference ?? {};

//   // Pastikan addon selalu memiliki nilai default (tidak null)
//   Map<String, Map<String, dynamic>> get safeAddon => addon ?? {};

//   // Pastikan notes memiliki nilai default (kosong jika null)
//   String get safeNotes => notes ?? '';
// }

// class Cart extends ChangeNotifier {
//   List<CartItem> _items = [];
//   VoidCallback? _onCartChanged; // Callback to notify changes
//   CartVoucher _usedVoucher = CartVoucher(
//     id: "",
//     name: "",
//     totalDiscount: 0,
//     voucher: {}, // You can provide default values for voucher as well
//   );
//   bool isVoucherCanUse = false;

//   Cart({VoidCallback? onCartChanged}) : _onCartChanged = onCartChanged {
//     // Set the initial cart items from AppState
//     _items = List.from(AppState().cartItems);
//   }

//   List<CartItem> get items => List.from(_items);

//   void useVoucher(CartVoucher voucher) {
//     _usedVoucher = voucher;
//     notifyListeners();
//   }

//   int calculateVoucher() {
//     Map<String, dynamic> recapCart = this.recapCart();
//     int total = 0;

//     if (_usedVoucher.voucher['discount_amount'] > 0) {
//       // print(_usedVoucher.voucher['discount_amount']);
//       // print(recapCart['totalPrice']);
//       int dscamt = _usedVoucher.voucher['discount_amount'].round();
//       total = min(dscamt, recapCart['totalPrice']);
//     } else if (_usedVoucher.voucher['discount_percentage'] > 0) {
//       total = (_usedVoucher.voucher['discount_percentage'] *
//               recapCart['totalPrice'] /
//               100)
//           .round();
//     }

//     return total;
//   }

//   bool checkEligibility() {
//     Map<String, dynamic> recapCart = this.recapCart();

//     // check price requirements
//     if (recapCart['totalPrice'] < _usedVoucher.voucher['minimum_spending']) {
//       isVoucherCanUse = false;
//       return false;
//     }

//     isVoucherCanUse = true;
//     return true;
//   }

//   void _recalculateTotalPrice() {
//     for (var item in _items) {
//       item.totalPrice = item.qty * item.price;
//     }
//   }

//   void addItem(CartItem newItem, {CartMode mode = CartMode.add}) {
//     // Check if the item with the same ID already exists
//     var existingItem = _items.firstWhere(
//       (item) => item.id == newItem.id,
//       orElse: () => CartItem(
//         id: '',
//         name: '',
//         qty: 0,
//         price: 0,
//         itemName: '',
//         preference: {},
//         addon: {},
//         notes: '',
//       ),
//     ); // Return an empty CartItem if not found

//     if (existingItem.id.isNotEmpty) {
//       // Item already exists, update the quantity
//       if (mode == CartMode.add) {
//         existingItem.qty += newItem.qty;
//       } else {
//         // Default behavior: Add a new item
//         existingItem.qty = newItem.qty;
//       }
//     } else {
//       // Item doesn't exist, add a new item
//       _items.add(newItem);
//     }

//     // Recalculate total price
//     _recalculateTotalPrice();

//     // Notify changes
//     notifyListeners();
//   }

//   void removeItem(String itemId) {
//     _items.removeWhere((item) => item.id == itemId);

//     // Recalculate total price
//     _recalculateTotalPrice();

//     // Notify changes
//     _onCartChanged?.call();

//     // Update app state
//     AppState().updateCart(_items);
//   }

//   void clearCart() {
//     _items.clear();

//     // Recalculate total price
//     _recalculateTotalPrice();

//     // Notify changes
//     _onCartChanged?.call();

//     // Update app state
//     AppState().updateCart(_items);
//   }

//   // you can disable this if this
//   bool isItemInCart(String itemId) {
//     return AppState().cartItems.any((item) => item.id == itemId);
//   }

//   Map<String, dynamic> getItemCart(String itemName) {
//     List<CartItem> data = [];
//     Map<String, int> indexes = {};

//     int index = 0;
//     for (var item in AppState().cartItems) {
//       if (item.name == itemName) {
//         indexes[item.id] = index;
//         data.add(item);
//       }
//       index++;
//     }

//     return {"data": data, "index": indexes};

//     // return {
//     //   "index": indexes,
//     //   "data": result
//     // }

//     // return AppState.cartItems
//     //     .where((item) => item.name == itemName)
//     //     .toList();
//   }

//   CartItem getItemByIndex(int index) {
//     return AppState().cartItems[index];
//   }

//   List<CartItem> getAllItemCart() {
//     return AppState().cartItems.toList();
//   }

//   Map<String, dynamic> recapCart() {
//     // Summarize quantities and total price based on item names
//     Map<String, dynamic> recap = {
//       'totalPrice': 0,
//       'totalItem': 0,
//       'items': {},
//     };

//     for (var item in AppState().cartItems) {
//       recap['totalPrice'] += item.totalPrice;

//       if (!recap['items'].containsKey(item.name)) {
//         recap['items'][item.name] = {
//           'name': item.itemName,
//           'preference': item.preference,
//           'totalQty': item.qty,
//           'totalPrice': item.totalPrice,
//           'notes': item.notes,
//           'addon': item.addon,
//         };
//         recap['totalItem'] += 1;
//       } else {
//         recap['items'][item.name]['totalQty'] += item.qty;
//         recap['items'][item.name]['totalPrice'] += item.totalPrice;
//       }
//     }

//     return recap;
//   }
// }

// String getPreferenceText(Map<String, String> data) {
//   // Get the values from the map
//   List<String> values = data.values.cast<String>().toList();

//   // Join the values into a comma-separated string
//   String result = values.join(', ');

//   return result;
// }

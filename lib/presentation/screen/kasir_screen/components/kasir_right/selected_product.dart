import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_right/product_detail_edit_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/presentation/screen/kasir_screen/components/kasir_left/product_detail_form.dart';

class SelectedProductsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.cartItems;

        if (cartItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No products selected',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return Column(
          children: cartItems.map((item) {
            // Use Dismissible for swipe-to-delete functionality
            return Dismissible(
              key: Key(item.id ?? DateTime.now().toString()),
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                // Show confirmation dialog
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm"),
                      content:
                          Text("Are you sure you want to remove this item?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("REMOVE"),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                // Remove the item from the cart
                cartProvider.removeCartItem(item.id ?? '');
              },
              child: GestureDetector(
                onTap: () {
                  _showProductDetailDialog(context, cartProvider, item);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris 1: Nama Produk x Jumlah & Total Harga
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.itemName} x ${item.qty}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  formatter.format(
                                      item.amount ?? (item.rate! * item.qty!)),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 6),

                        // Baris 2: Grup Item
                        if (item.itemCode != null)
                          Text(
                            'Code: ${item.itemCode}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showProductDetailDialog(
      BuildContext context, CartProvider cartProvider, CartItem cartItem) {
    // Parse existing notes if available
    String customerName = '';
    String? selectedSize;
    List<String> selectedFeatures = [];

    if (cartItem.notes != null && cartItem.notes!.isNotEmpty) {
      try {
        // Extract customer name
        final customerPattern = RegExp(r'Customer: (.*?),');
        final customerMatch = customerPattern.firstMatch(cartItem.notes!);
        if (customerMatch != null && customerMatch.groupCount >= 1) {
          customerName = customerMatch.group(1) ?? '';
        }

        // Extract size
        final sizePattern = RegExp(r'Size: (.*?),');
        final sizeMatch = sizePattern.firstMatch(cartItem.notes!);
        if (sizeMatch != null && sizeMatch.groupCount >= 1) {
          selectedSize = sizeMatch.group(1);
        }

        // Extract add-ons
        final addonsPattern = RegExp(r'Add-ons: (.*?)$');
        final addonsMatch = addonsPattern.firstMatch(cartItem.notes!);
        if (addonsMatch != null && addonsMatch.groupCount >= 1) {
          final addonsString = addonsMatch.group(1) ?? '';
          selectedFeatures = addonsString
              .split(', ')
              .where((feature) => feature.isNotEmpty)
              .toList();
        }
      } catch (e) {
        // If there's an error parsing, just continue with empty values
        print('Error parsing notes: $e');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDetailEditDialog(
          cartItem: cartItem,
          cartProvider: cartProvider,
          initialCustomerName: customerName,
          initialSize: selectedSize,
          initialFeatures: selectedFeatures,
          initialDiscountValue:
              cartItem.discountValue ?? 0.0, // Nilai diskon awal
          initialIsDiscountPercent:
              cartItem.isDiscountPercent ?? false, // Jenis diskon
        );
      },
    );
  }
}

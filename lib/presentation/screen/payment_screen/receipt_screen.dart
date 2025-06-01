import 'package:flutter/material.dart';
import 'package:pos/data/models/cart_item.dart';
import 'package:pos/core/providers/cart_provider.dart';
import 'package:provider/provider.dart';

import '../setting_screen/print_screen/funct_print.dart';

class ReceiptScreen extends StatelessWidget {
  final int totalTagihan;
  final List<CartItem> orders;
  final String customerName;
  final String orderType;
  final int? cashAmount;
  final String? modeOfPayment;
  final String? referenceNumber;
  final int kembalian;

  const ReceiptScreen({
    required this.totalTagihan,
    required this.orders,
    required this.customerName,
    required this.orderType,
    this.cashAmount,
    this.modeOfPayment,
    this.referenceNumber,
    required this.kembalian,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar removed as requested
      body: Stack(
        children: [
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 350),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Title at top
                        Text(
                          'STRUK PEMBAYARAN',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        // 2. Cost center
                        Text(
                          'Main - M',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        // 3. Address
                        Text(
                          'Jl. Contoh No. 123, Kota',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Telp: 021-123456',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        // 4. Print status
                        Text(
                          'PRINTED',
                          style: TextStyle(
                              fontSize: 10, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                        // 5. Horizontal separator
                        Divider(thickness: 1),
                        // 6-8. Invoice details
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Row 1
                              Row(
                                children: [
                                  // Column 1
                                  Expanded(
                                    flex: 1,
                                    child: Text('No:'),
                                  ),
                                  // Column 2
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)} - ${DateTime.now().toString().split(' ')[0]} - ${TimeOfDay.now().format(context)}',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              // Row 2
                              Row(
                                children: [
                                  // Column 1
                                  Expanded(
                                    flex: 1,
                                    child: Text('Status:'),
                                  ),
                                  // Column 2
                                  Expanded(
                                    flex: 2,
                                    child: Text(orderType),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              // Row 3
                              Row(
                                children: [
                                  // Column 1
                                  Expanded(
                                    flex: 1,
                                    child: Text('Customer:'),
                                  ),
                                  // Column 2
                                  Expanded(
                                    flex: 2,
                                    child: Text(customerName),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              // Row 4
                              Row(
                                children: [
                                  // Column 1
                                  Expanded(
                                    flex: 1,
                                    child: Text('Kasir:'),
                                  ),
                                  // Column 2
                                  Expanded(
                                    flex: 2,
                                    child: Text('Administrator'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 9. Horizontal separator after the columns
                        Divider(thickness: 1),

                        // 10-11. Per-item display in receipt
                        ...orders.map((order) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item name - size
                                  Text(
                                    '${order.itemName} - ${order.uom ?? "Regular"}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  // Qty x Price and Total in one row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${order.qty} x Rp.${order.rate}'),
                                      Text('Rp.${order.amount}'),
                                    ],
                                  ),
                                  // Add-ons if any
                                  if (order.notes != null)
                                    Text(
                                      '${order.notes}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            )),

                        // 12. Horizontal separator after items
                        Divider(thickness: 1),

                        // 13. Bold total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Rp.${totalTagihan}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),

                        // 14. Horizontal separator
                        Divider(thickness: 1),

                        // 15. Payment method and amount/reference
                        if (modeOfPayment != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$modeOfPayment:'),
                              Text(modeOfPayment == "Cash"
                                  ? 'Rp.$cashAmount'
                                  : '${referenceNumber ?? ""}'),
                            ],
                          ),

                        // 16. Change amount
                        if (modeOfPayment == "Cash" && cashAmount != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Change:'),
                              Text('Rp.$kembalian'),
                            ],
                          ),

                        SizedBox(height: 16),

                        Text(
                          'Terima Kasih',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Silahkan datang kembali',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating action buttons at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Print button
                  FloatingActionButton.extended(
                    heroTag: "print",
                    backgroundColor: Colors.blue,
                    icon: Icon(Icons.print, color: Colors.white),
                    label: Text('Print', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add print functionality here
                      Map<String, dynamic> transaction = {
                        'transactionId':
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'transactionDate': DateTime.now().toString(),
                        'cashierName': 'Administrator',
                        'subtotal': totalTagihan,
                        'tax': (totalTagihan * 0.1).toInt(),
                        'total': (totalTagihan * 1.1).toInt(),
                        'paymentMethod': modeOfPayment ?? 'Tunai',
                        'paid': cashAmount ?? 0,
                        'change': kembalian,
                      };

                      List<Map<String, dynamic>> orderItems =
                          orders.map((order) {
                        return {
                          'name': order.itemName,
                          'quantity': order.qty,
                          'price': order.rate,
                        };
                      }).toList();

                      printReceipt(context, transaction, orderItems);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mencetak struk...')),
                      );
                    },
                  ),

                  // Share button
                  FloatingActionButton.extended(
                    heroTag: "share",
                    backgroundColor: Colors.green,
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text('Share', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Add share functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berbagi struk...')),
                      );
                    },
                  ),

                  // Selesai/Done button
                  FloatingActionButton.extended(
                    heroTag: "selesai",
                    backgroundColor: Colors.orange,
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label:
                        Text('Selesai', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      // Navigate back to previous screen
                      Navigator.pop(context);
                      // Bersihkan keranjang menggunakan CartProvider
                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);
                      cartProvider.clearCart();
                      Navigator.pushReplacementNamed(context, '/kasir');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pos/data/models/cart_item.dart';

class OrderListCard extends StatelessWidget {
  final List<CartItem> orders;

  const OrderListCard({
    Key? key,
    required this.orders,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Orders: $orders'); // Debugging log
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Membungkus seluruh konten agar bisa discroll
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Gunakan ListView biasa dengan shrinkWrap
              orders.isEmpty
                  ? Center(child: Text('Tidak ada data pesanan'))
                  : ListView.builder(
                      shrinkWrap:
                          true, // Agar ListView menyesuaikan tinggi konten
                      physics:
                          const NeverScrollableScrollPhysics(), // ListView tidak scroll sendiri
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: ${order.itemCode}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Qty: ${order.qty}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Item Name: ${order.itemName}'),
                                Text('Harga: Rp. ${order.rate}'),
                                Text(
                                    'Subtotal: Rp. ${order.rate! * order.qty!}'),
                                if (order.itemCode != null)
                                  Text('Kode Item: ${order.itemCode}'),
                                if (order.description != null)
                                  Text('Description: ${order.description}'),
                                if (order.uom != null)
                                  Text('UOM: ${order.uom}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pos/core/providers/print_state.dart';
import '../../setting_screen/print_screen/funct_print.dart';

class TransactionDetailWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final List<Map<String, dynamic>> orderItems;

  const TransactionDetailWidget({
    Key? key,
    required this.transaction,
    required this.orderItems,
  }) : super(key: key);

  Widget _getPaymentIcon(String paymentMethod) {
    IconData iconData;
    Color iconColor;

    switch (paymentMethod) {
      case 'Tunai':
        iconData = Icons.money;
        iconColor = Colors.green;
        break;
      case 'Debit':
        iconData = Icons.credit_card;
        iconColor = Colors.blue;
        break;
      case 'QRIS':
        iconData = Icons.qr_code;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.receipt;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor);
  }

  Widget _getPaymentMethodChip(String paymentMethod) {
    Color chipColor;
    IconData iconData;

    switch (paymentMethod) {
      case 'Tunai':
        chipColor = Colors.green;
        iconData = Icons.money;
        break;
      case 'Debit':
        chipColor = Colors.blue;
        iconData = Icons.credit_card;
        break;
      case 'QRIS':
        chipColor = Colors.purple;
        iconData = Icons.qr_code;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.receipt;
    }

    return Chip(
      backgroundColor: chipColor.withOpacity(0.1),
      side: BorderSide(color: chipColor),
      label: Text(paymentMethod),
      avatar: Icon(iconData, color: chipColor, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme color based on payment method
    Color themeColor;
    switch (transaction['paymentMethod'] ?? 'Lainnya') {
      case 'Tunai':
        themeColor = Colors.green;
        break;
      case 'Debit':
        themeColor = Colors.blue;
        break;
      case 'QRIS':
        themeColor = Colors.purple;
        break;
      default:
        themeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: themeColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: themeColor.withOpacity(0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: themeColor, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '#${transaction['transactionId']?.toString() ?? ''}'),
                      ],
                    ),
                  ],
                ),
                _getPaymentMethodChip(
                    transaction['paymentMethod'] ?? 'Lainnya'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transaction info
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction date and cashier info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggal',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                              transaction['transactionDate']?.toString() ?? ''),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Kasir',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(transaction['cashierName']?.toString() ?? ''),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Customer name
                  const Text('Nama Customer',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(transaction['customerName']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),

                  const SizedBox(height: 16),

                  // Payment method
                  const Text('Metode Pembayaran',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      _getPaymentIcon(
                          transaction['paymentMethod'] ?? 'Lainnya'),
                      const SizedBox(width: 4),
                      Text(
                        transaction['paymentMethod'] ?? 'Lainnya',
                        style: TextStyle(
                            color: themeColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  if ((transaction['paymentMethod'] ?? '') != 'Tunai' &&
                      (transaction['referralCode']?.toString() ?? '')
                          .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Kode Referensi',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(transaction['referralCode']?.toString() ?? ''),
                  ],

                  const SizedBox(height: 24),

                  // Purchase details
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: themeColor.withOpacity(0.3)),
                        bottom: BorderSide(color: themeColor.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 6,
                          child: Text('Item',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('Qty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Harga',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),

                  // Order items
                  if (orderItems.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final productName = item['productName']?.toString() ??
                            item['name']?.toString() ??
                            '';
                        final quantity = item['quantity'] ?? 0;
                        final price = item['price'] ?? 0;
                        final subtotal = item['subtotal'] ?? (price * quantity);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Text(productName),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${quantity}x',
                                    textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Rp ${subtotal.toString()}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Payment details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(
                                'Rp ${transaction['subtotal']?.toString() ?? '0'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pajak 10%'),
                            Text('Rp ${transaction['tax']?.toString() ?? '0'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: themeColor.withOpacity(0.3)),
                              bottom: BorderSide(
                                  color: themeColor.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  'Rp ${transaction['total']?.toString() ?? '0'}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: themeColor)),
                            ],
                          ),
                        ),
                        if (transaction['paid'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dibayar'),
                              Text('Rp ${transaction['paid'].toString()}'),
                            ],
                          ),
                        ],
                        if ((transaction['paymentMethod'] ?? '') == 'Tunai' &&
                            transaction['change'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian'),
                              Text('Rp ${transaction['change'].toString()}'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      printReceipt(context, transaction, orderItems);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share berhasil!')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: themeColor,
                      side: BorderSide(color: themeColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

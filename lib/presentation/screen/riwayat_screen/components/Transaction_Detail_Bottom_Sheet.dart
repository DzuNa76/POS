import 'package:flutter/material.dart';
import 'package:pos/core/providers/print_state.dart';
import '../../setting_screen/print_screen/funct_print.dart';
import 'package:intl/intl.dart';

class TransactionDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final List<Map<String, dynamic>> orderItems;

  const TransactionDetailBottomSheet({
    Key? key,
    required this.transaction,
    required this.orderItems,
  }) : super(key: key);

  // Format mata uang dengan pemisah ribuan
  String formatCurrency(dynamic amount) {
    // Pastikan amount adalah num (int atau double)
    num numAmount = 0;
    if (amount is num) {
      numAmount = amount;
    } else if (amount is String) {
      numAmount = num.tryParse(amount) ?? 0;
    }

    // Format dengan NumberFormat dari intl package
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(numAmount);
  }

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

  @override
  Widget build(BuildContext context) {
    Color themeColor;
    switch (transaction['paymentMethod']) {
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
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: themeColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ID Transaksi', style: TextStyle(fontSize: 12)),
                  Text('#${transaction['transactionId']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(transaction['transactionDate'],
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nama Customer'),
              Text(transaction['customerName']),
            ],
          ),
          Row(
            children: [
              _getPaymentIcon(transaction['paymentMethod']),
              const SizedBox(width: 4),
              Text(
                transaction['paymentMethod'],
                style:
                    TextStyle(color: themeColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (transaction['paymentMethod'] != 'Tunai' &&
              transaction['referralCode'].isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kode Referensi'),
                Text(transaction['referralCode']),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kasir'),
              Text(transaction['cashierName']),
            ],
          ),
          Divider(height: 32, color: themeColor.withOpacity(0.3)),
          const Text('Detail Pembelian',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Header for the items list
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Text('Item',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Harga',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // Improved list with dotted line for each item
          Expanded(
            child: ListView.builder(
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                final totalItemPrice = item['price'] * item['quantity'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Item name section
                          Expanded(
                            flex: 6,
                            child: Text(
                              '${item['quantity']}x ${item['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Price section with formatted currency
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Rp ${formatCurrency(totalItemPrice)}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),

                      // Dotted line below each item
                      CustomPaint(
                        painter: DottedLinePainter(themeColor.withOpacity(0.3)),
                        size: Size(MediaQuery.of(context).size.width - 32, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 32, color: themeColor.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('Rp ${formatCurrency(transaction['subtotal'])}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pajak 10%'),
              Text('Rp ${formatCurrency(transaction['tax'])}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text('Rp ${formatCurrency(transaction['total'])}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: themeColor)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dibayar'),
              Text('Rp ${formatCurrency(transaction['paid'])}'),
            ],
          ),
          // Show outstanding amount from payment_schedule
          if (transaction.containsKey('outstanding') &&
              transaction['outstanding'] > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sisa Tagihan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp ${formatCurrency(transaction['outstanding'])}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          if (transaction['paymentMethod'] == 'Tunai')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian'),
                Text('Rp ${formatCurrency(transaction['change'])}'),
              ],
            ),
          const SizedBox(height: 16),
          Row(
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
        ],
      ),
    );
  }
}

// Dotted line painter untuk garis lurus horizontal
class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 3;
    const double dashSpace = 3;
    double startX = 0;

    // Gambar garis putus-putus horizontal sepanjang lebar widget
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

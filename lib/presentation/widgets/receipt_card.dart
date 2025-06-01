import 'package:flutter/material.dart';

class ReceiptCard extends StatelessWidget {
  final String transactionId;
  final String customerName;
  final String paymentType;
  final String cashierName;
  final String transactionDate;
  final List<Map<String, dynamic>> orderDetails;
  final int subtotal;
  final int tax;
  final int total;
  final int paid;
  final int change;

  const ReceiptCard({
    Key? key,
    required this.transactionId,
    required this.customerName,
    required this.paymentType,
    required this.cashierName,
    required this.transactionDate,
    required this.orderDetails,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informasi transaksi
            _buildTextRow("ID Transaksi", transactionId),
            _buildTextRow("Nama Customer", customerName),
            _buildTextRow("Tipe Pembayaran", paymentType),
            _buildTextRow("Kasir", cashierName),
            _buildTextRow("Tanggal Transaksi", transactionDate),
            const Divider(), // Garis pemisah setelah tanggal transaksi

            // Detail Pembelian
            const Text(
              "Detail Pembelian",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...orderDetails.map((order) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom nama produk dan jumlah x harga
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['name']),
                        Text('${order['quantity']} x Rp ${order['price']}'),
                      ],
                    ),
                  ),
                  // Kolom hasil subtotal
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Rp ${order['subtotal']}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            }).toList(),
            const Divider(), // Garis pemisah setelah detail pembelian

            // Informasi pembayaran
            _buildTextRow("Subtotal", 'Rp $subtotal'),
            _buildTextRow("Pajak 10%", 'Rp $tax'),
            _buildTextRow("Total", 'Rp $total'),
            _buildTextRow("Dibayar", 'Rp $paid'),
            _buildTextRow("Kembalian", 'Rp $change'),
          ],
        ),
      ),
    );
  }

  // Helper untuk membuat baris teks
  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

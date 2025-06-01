import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl untuk formatter mata uang

class TransactionListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String searchQuery;
  final bool isLoading;
  final Function buildEmptyMessage;
  final Function(BuildContext, String) onTransactionTap;
  final String? selectedTransactionId;

  const TransactionListWidget({
    Key? key,
    required this.transactions,
    required this.searchQuery,
    required this.isLoading,
    required this.buildEmptyMessage,
    required this.onTransactionTap,
    this.selectedTransactionId,
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Text(buildEmptyMessage()),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final transactionId = transaction['transactionId'];
        final isSelected = selectedTransactionId == transactionId;

        // Tentukan warna berdasarkan metode pembayaran
        Color? themeColor;
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

        return Card(
          elevation: isSelected ? 3 : 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isSelected ? themeColor.withOpacity(0.1) : null,
          shape: isSelected
              ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: themeColor, width: 2),
          )
              : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTransactionTap(context, transactionId),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#$transactionId',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? themeColor : null,
                        ),
                      ),
                      Text(
                        transaction['transactionDate'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          transaction['customerName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _getPaymentIcon(transaction['paymentMethod']),
                          const SizedBox(width: 4),
                          Text(
                            'Rp ${formatCurrency(transaction['total'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Menambahkan informasi tambahan jika ada outstanding payment
                  if (transaction.containsKey('outstanding') && transaction['outstanding'] > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Sisa: Rp ${formatCurrency(transaction['outstanding'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    return Icon(iconData, color: iconColor, size: 16);
  }
}
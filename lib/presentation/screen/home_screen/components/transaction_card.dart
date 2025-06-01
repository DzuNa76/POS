import 'package:flutter/material.dart';
import 'package:pos/data/models/models.dart';
import 'package:pos/presentation/widgets/widgets.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TransactionData> dummyTransactions = [
      TransactionData(
        customerName: 'Testing 1',
        status: 'Completed',
        type: 'Dine In',
        transactionId: '001',
        date: '2025-02-25',
        totalOrder: 'Rp 150,000',
      ),
      TransactionData(
        customerName: 'Testing 2',
        status: 'Pending',
        type: 'Take Away',
        transactionId: '002',
        date: '2025-02-26',
        totalOrder: 'Rp 200,000',
      ),
      TransactionData(
        customerName: 'Testing 3',
        status: 'Completed',
        type: 'Dine In',
        transactionId: '003',
        date: '2025-02-26',
        totalOrder: 'Rp 300,000',
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Transaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Menggunakan SmallButton
                SmallButton(
                  text: 'View History',
                  onPressed: () {
                    // Navigate to History Page
                    Navigator.pushNamed(context, '/history');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: dummyTransactions.take(3).map((transaction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildTransactionRow('Status', transaction.type),
                          _buildTransactionRow(
                              'Transaction ID', transaction.transactionId),
                          _buildTransactionRow('Date', transaction.date),
                          _buildTransactionRow(
                              'Order Total', transaction.totalOrder),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
